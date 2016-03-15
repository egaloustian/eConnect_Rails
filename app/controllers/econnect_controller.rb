require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'soap/wsdlDriver'
require 'uri'
require 'json'
require 'mapdef.rb'
require 'securerandom'
require 'csv'
require 'active_record'
require 'configure.rb'


class EconnectController < ApplicationController
  @@headerCache  = []
  @@detailsCache = []
  @@allRecords  = []
  @@headerBuff  = []
  @@filename = ""

  def filequeue
    @filelist = []
    path  = Config::INPUT_FILE_PATH + "*.csv"

    Dir.glob(path) do |filename|
      @filelist << filename
    end
  end


  def procDetails
    client = Savon.client(wsdl: "http://www.dneonline.com/calculator.asmx?wsdl")
    message = {
      "intA" => 20,
      "intB" => 5
    }
    response = client.call(:divide,  message: message )
    hash = response.body
    el1=hash[:divide_response]
    @result=el1[:divide_result]

    generateDetails
  end


  def procHeader
    generateHeader
  end

  def procHeaderHist
    @grid = []
    headerHist = Header.all
    headerHist.each do |hdr|
      rec = {}
      rec[:batchid] =  hdr.BatchID
      rec[:voucher] =  hdr.VoucherNo
      rec[:payablesbatch] =  hdr.Payables
      rec[:doctype] =  hdr.DocType
      rec[:description] = hdr.Description
      rec[:vendor] = hdr.Vendor
      rec[:remittoid] = hdr.RemitToID
      rec[:docdate] = hdr.DocDate
      rec[:docnumber] = hdr.DocNumber
      rec[:purchaseamount] = hdr.PurchaseAmount
      rec[:postingdate] = hdr.PostingDate
      rec[:ponumber] = hdr.PO
      rec[:bssi_facility] = hdr.BSSI_Facility
      rec[:bssi_department] = hdr.BSSI_Department
      rec[:bssi_accountsub] = hdr.BSSI_Accountsub
      rec[:bssi_intercompany] = hdr.BSSI_Intercompany
      rec[:carrier_handler] = hdr.Carrier
      rec[:sourceFile] = hdr.FileName
      @grid << rec
    end
  end

  def procDetailsHist
    @grid = []
    detailHist = Detail.all
    detailHist.each do |dtl|
      rec = {}
      rec[:batchid] = dtl.BatchID
      rec[:voucher] = dtl.VoucherNo
      rec[:disttype] = dtl.DistType
      rec[:debitamt] = dtl.DebitAmt
      rec[:creditamt] = dtl.CreditAmt
      rec[:account] = dtl.Account
      rec[:aggaccount] = dtl.AccountAgg
      rec[:vendor] = dtl.Vendor
      rec[:sourceFile] = dtl.FileName

      @grid << rec
    end
  end


def generateDetails
    @grid = []
    @@allRecords.sort {|a,b| a[O::VOUCHER] <=> b[O::VOUCHER]}
    @@allRecords.each do |r|
             detail = {}
             detail[:batchid] = r[O::BATCHID]
             detail[:voucher] = r[O::VOUCHER]
  	         moneyamt = r[O::JOURNAL_AMOUNT].to_f

		        if(moneyamt>=0.0)
		            debitamt = moneyamt.abs
                creditamt = 0
                dist="PURCH"
  	        else
               creditamt =  moneyamt.abs
               debitamt = 0
               dist="PAY"
            end

		        detail[:disttype]=dist
            detail[:debitamt]=debitamt
            detail[:creditamt]=creditamt
            time = Time.new
            cur_date = time.strftime("%Y-%m-%d %H:%M:%S")
            cur_date = time.strftime("MM/dd/yyyy")
            detail[:creatdttm]=cur_date
            detail[:account] = r[O::ACCOUNT]
            detail[:aggaccount] = r[O::AGG_ACCOUNT]
            detail[:vendor] = r[O::VENDOR]

            @grid << detail
            @@detailsCache << detail
          end
end




def generateHeader
             @grid = []
      	     @@headerBuff.each do |r|
             header = {}
             header[:batchid] = r[O::BATCHID]
             header[:voucher] = r[O::VOUCHER] #lines[0][I::PO_NUMBER]
             header[:description] = r[O::DESCRIPTION].to_s
             header[:vendor] = r[O::VENDOR]
             header[:remittoid] = r[O::REMIT_TO_ID]
             header[:docnumber] = r[O::DOC_NUMBER]
             header[:ponumber]=r[O::PO_NUMBER]
             header[:purchaseamount] = r[O::PURCHASE_AMOUNT]
             header[:bssi_facility] = r[O::BSSI_FACILITY]
             header[:bssi_department] = 0
             header[:bssi_accountsub] = 0
             header[:bssi_intercompany] = r[O::BSSI_INTERCOMPANY]
             header[:carrier_handler] = r[O::CARRIER_HANDLER]
             header[:sourcefile] = r[O::SOURCE_FILE]
            time = Time.new
#ssis            cur_date = time.strftime("%m/%d/%Y")
            cur_date = time.strftime("%Y-%m-%d")
            header[:postingdate] = cur_date

            if(r[O::DOC_DATE] !=nil)
              doctime = Time.parse(r[O::DOC_DATE].to_str)
#SSIS              doctime = doctime.strftime("%m/%d/%Y")
              doctime = doctime.strftime("%Y-%m-%d")
            end
            header[:docdate] =doctime

            doctype = r[O::DOC_TYPE]=="DR"?doctype="Invoice" : "Credit-Memo"
            header[:doctype] = doctype

            cur_date = time.strftime("%y%m%d%p")
            scode = r[O::BSSI_MAX] == 1?'IC':'NC'
            payablebatch = r[O::BSSI_FACILITY].to_s + scode + cur_date
            header[:payablesbatch] = payablebatch

            @grid << header
            @@headerCache << header
      	end
end

def procItem
      thisid = params[:id]
      @thisitem = thisid.to_s
      flash[:notice] = "message sent!"
end

def edit_item(obj)
  #thisitem=@grid.to_a.find(index)
  #render :json=>@grid
  render :json=>obj
  #respond_to do |format|
  #    format.json(render :json=>@grid)
  #  end
end

def loadInputFromFile
  @@allRecords.clear
  @@headerCache.clear
  @@detailsCache.clear
  @@headerBuff.clear
  @@filename = params[:id]
  #batchid=SecureRandom.uuid
  time = Time.new
  date = time.strftime("%Y%m%d")
  id = (Time.parse(time.to_s).seconds_since_midnight/60).to_i
  batchid = "B-" + date + "-" + id.to_s

  #"/home/egaloustian/MongoApp1/input/concur5.csv"
  vouchernum=1001
  vouchernum = Header.max(:VoucherNo)+1
  #h.find("VoucherNo" => vouchernum).sort({"VoucherNo" => -1}).limit(1).first()

    CSV.foreach(@@filename, {:col_sep =>"|"} ) do |row|
    rec=[]
    if(row[0] != nil && row[0]=='DETAIL')
      rec[O::PO_NUMBER]=row[I::PO_NUMBER]
      rec[O::DESCRIPTION]=row[I::DESCRIPTION]
      rec[O::DOC_NUMBER]=row[I::DOC_NUMBER]
      rec[O::DOC_DATE]=row[I::DOC_DATE]
      rec[O::PURCHASE_AMOUNT]=row[I::PURCHASE_AMOUNT]
      rec[O::DELIVERY]=row[I::DELIVERY]
      rec[O::CARRIER_HANDLER]=row[I::CARRIER_HANDLER]
      rec[O::BSSI_FACILITY]=row[I::BSSI_FACILITY]
      rec[O::COMPANY_REQUEST_ORG]=row[I::COMPANY_REQUEST_ORG]
      rec[O::JOURNAL_ACCOUNT_CODE]=row[I::JOURNAL_ACCOUNT_CODE]
      rec[O::JOURNAL_AMOUNT]=row[I::JOURNAL_AMOUNT]
      rec[O::DOC_TYPE]=row[I::DOC_TYPE]
      rec[O::COMPANY_ALLOCATION]=row[I::COMPANY_ALLOCATION]
      rec[O::DIVISION_ALLOCATION]=row[I::DIVISION_ALLOCATION]
      rec[O::DEPARTMENT_ALLOCATION]=row[I::DEPARTMENT_ALLOCATION]
      rec[O::REMIT_TO_ID]=row[I::REMIT_TO_ID]
      rec[O::VENDOR]=row[I::VENDOR]
      rec[O::BATCHID]= batchid
      rec[O::SHA1KEY]= getSHA1Key(row)
      rec[O::TAG]=true
      rec[O::SOURCE_FILE] = @@filename
      rec[O::BSSI_INTERCOMPANY]=rec[O::COMPANY_ALLOCATION]==rec[O::COMPANY_REQUEST_ORG]?0:1

      acctnum= rec[O::COMPANY_ALLOCATION].to_s + "-" + rec[O::DIVISION_ALLOCATION].to_s +
           "-" + rec[O::DEPARTMENT_ALLOCATION].to_s  + "-" + rec[O::JOURNAL_ACCOUNT_CODE].to_s
#ssis      rec[O::AGG_ACCOUNT] = rec[O::BSSI_FACILITY] + "-000-0000-2500-25000"
      rec[O::AGG_ACCOUNT] = rec[O::COMPANY_REQUEST_ORG] + "-000-0000-2500-25000"

      rec[O::ACCOUNT] = acctnum
      @@allRecords << rec
    end
  end

    bssi_intercompany_max=
    @@headerBuff = @@allRecords.uniq{|x|[x[O::SHA1KEY]]}
    @@headerBuff.each do |r|
        r[O::VOUCHER] = vouchernum

        @@allRecords.each do |a|
            if(r[O::SHA1KEY] == a[O::SHA1KEY])
              a[O::BSSI_MAX]= a[O::BSSI_INTERCOMPANY] | r[O::BSSI_INTERCOMPANY]
              a[O::VOUCHER] = vouchernum
            end
        end
        vouchernum+=1
    end
    @@inputBuffer = @@allRecords
    #now add the balance
    @@headerBuff = @@allRecords.uniq{|x|[x[O::VOUCHER]]}
    @@headerBuff.each do |r|
      rec = []
      sumbalance=0.0
      @@allRecords.each do |a|
          if(r[O::SHA1KEY] == a[O::SHA1KEY])
            rec[O::VOUCHER] = a[O::VOUCHER]
            rec[O::BATCHID] = a[O::BATCHID]
            sumbalance += a[O::JOURNAL_AMOUNT].to_f
          end
        end
        if(rec[O::VOUCHER]!=nil)
          #SSIS - acctnum = r[O::COMPANY_REQUEST_ORG] + '-000-0000-2500-25000'
          #SSIS - rec[O::AGG_ACCOUNT] = acctnum
          rec[O::JOURNAL_AMOUNT] = -1 * sumbalance
          @@allRecords << rec
        end

    end
    generateDetails
    generateHeader
    render "procHeader"

end

def commitToDB
  commitInputToDB
  commitHeaderToDB
  commitDetailsToDB
end

def commitInputToDB
  @@inputBuffer.each do |rec|
    if( rec[O::TAG] == true)
      inp = Input.new
      inp.PONum  = rec[O::PO_NUMBER]
      inp.Description = rec[O::DESCRIPTION]
      inp.DocNum  = rec[O::DOC_NUMBER]
      inp.DocDate  = rec[O::DOC_DATE]
      inp.PurchaseAmt  = rec[O::PURCHASE_AMOUNT ]
      inp.Delivery  = rec[O::DELIVERY]
      inp.Carrier  = rec[O::CARRIER_HANDLER ]
      inp.BSSI_facility  = rec[O::BSSI_FACILITY ]
      inp.CompanyReqOrg  = rec[O::COMPANY_REQUEST_ORG]
      inp.JournalAcctCode  = rec[O::JOURNAL_ACCOUNT_CODE ]
      inp.JournaAmt  = rec[O::JOURNAL_AMOUNT]
      inp.DocType  = rec[O::DOC_TYPE ]
      inp.CompanyAlloc  = rec[O::COMPANY_ALLOCATION ]
      inp.DivAlloc  = rec[O::DIVISION_ALLOCATION ]
      inp.DeptAlloc  = rec[O::DEPARTMENT_ALLOCATION ]
      inp.RemittoID  = rec[O::REMIT_TO_ID ]
      inp.Vendor  = rec[O::VENDOR]
      inp.BatchID  = rec[O::BATCHID]
      inp.ShaKey  = rec[O::SHA1KEY]
      inp.Voucher  = rec[O::VOUCHER]
      inp.BSSI_Intercompany  = rec[O::BSSI_INTERCOMPANY]
      inp.BSSI_Max  = rec[O::BSSI_MAX]
      inp.Account  = rec[O::ACCOUNT]
      inp.AggAccount  = rec[O::AGG_ACCOUNT ]
      inp.AggSum  = rec[O::AGG_SUM ]
      inp.SourceFile  = rec[O::SOURCE_FILE ]
      inp.save
    end
  end
end

def commitHeaderToDB
  @@headerCache.each do |rec|
    hdr = Header.new
    hdr.BatchID = rec[:batchid]
    hdr.VoucherNo = rec[:voucher]
    hdr.Payables = rec[:payablesbatch]
    hdr.DocType = rec[:doctype]
    hdr.Description = rec[:description]
    hdr.Vendor = rec[:vendor]
    hdr.RemitToID = rec[:remittoid]
    hdr.DocDate = rec[:docdate]
    hdr.DocNumber = rec[:docnumber]
    hdr.PurchaseAmount = rec[:purchaseamount]
    hdr.PostingDate = rec[:postingdate]
    hdr.PO = rec[:ponumber]
    hdr.BSSI_Facility = rec[:bssi_facility]
    hdr.BSSI_Department = rec[:bssi_department]
    hdr.BSSI_Accountsub = rec[:bssi_accountsub]
    hdr.BSSI_Intercompany = rec[:bssi_intercompany]
    hdr.Carrier = rec[:carrier_handler]
    hdr.FileName = rec[:sourceFile]
    hdr.save
  end
end

def commitDetailsToDB
  @@detailsCache.each do |rec|
    dtl = Detail.new
    dtl.BatchID = rec[:batchid]
    dtl.VoucherNo = rec[:voucher]
    dtl.Account = rec[:account]
    dtl.DistType = rec[:disttype]
    dtl.DebitAmt = rec[:debitamt]
    dtl.CreditAmt = rec[:creditamt]
    dtl.AccountAgg = rec[:aggaccount]
    dtl.Vendor = rec[:vendor]
    dtl.FileName = rec[:sourceFile]
    dtl.save
  end
end


def getSHA1Key  (r)
  stringKey = r[I::DOC_TYPE].to_s + r[I::DESCRIPTION].to_s +
  r[I::VENDOR].to_s + r[I::REMIT_TO_ID].to_s + r[I::DOC_DATE].to_s+
  r[I::DOC_NUMBER].to_s  + r[I::PO_NUMBER].to_s+
  r[I::BSSI_FACILITY].to_s
  sh1key = Digest::SHA1.hexdigest stringKey
  return sh1key
end

def show
end

























end
