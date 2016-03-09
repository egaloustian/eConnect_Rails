require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'soap/wsdlDriver'
require 'uri'
require 'json'
require 'global_constants.rb'
require 'securerandom'
require 'csv'
require 'active_record'
#require 'wss4r/rpc/wssdriver'


class PersistDB < ActiveRecord::Base
  def connect
  end

  def disconnect
  end
end

class EconnectController < ApplicationController
  @@headerCache = []
  @@detailsCache =[]
  @@allRecords = []


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
    doMapDetails
  end


  def procHeader
    doMapHeader
  end

  def actionC
  end


def doMapDetails
    @grid = []
    @@allRecords.sort {|a,b| a[OUT::VOUCHER] <=> b[OUT::VOUCHER]}
    @@allRecords.each do |r|
             detail = {}
             detail[:batchid] = r[OUT::BATCHID]
             detail[:voucher] = r[OUT::VOUCHER]
  	         moneyamt = r[OUT::JOURNAL_AMOUNT].to_f

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
            detail[:account] = r[OUT::AGG_ACCOUNT]

            @grid << detail
          end
          @@detailsCache = @grid.dup
end




def doMapHeader
            @grid = []
      	   @@headerBuff.each do |r|
             header = {}
             header[:batchid] = r[OUT::BATCHID]
             header[:voucher] = r[OUT::VOUCHER] #lines[0][IN::PO_NUMBER]
             header[:description] = r[OUT::DESCRIPTION].to_s
             header[:vendor] = r[OUT::VENDOR]
             header[:remittoid] = r[OUT::REMIT_TO_ID]
             header[:docnumber] = r[OUT::DOC_NUMBER]
             header[:ponumber]=r[OUT::PO_NUMBER]
             header[:purchaseamount] = r[OUT::PURCHASE_AMOUNT]
             header[:bssi_facility] = r[OUT::BSSI_FACILITY]
             header[:bssi_department] = 0
             header[:bssi_accountsub] = 0
             header[:bssi_intercompany] = r[OUT::BSSI_INTERCOMPANY]
             header[:carrier_handler] = r[OUT::CARRIER_HANDLER]
            time = Time.new
            cur_date = time.strftime("%m/%d/%Y")
            header[:postingdate] = cur_date

            if(r[OUT::DOC_DATE] !=nil)
              doctime = Time.parse(r[OUT::DOC_DATE].to_str)
              doctime = doctime.strftime("%m/%d/%Y")
            end
            header[:docdate] =doctime

            doctype = r[OUT::DOC_TYPE]=="DR"?doctype="Invoice" : "Credit-Memo"
            header[:doctype] = doctype

            cur_date = time.strftime("%Y%m%d")
            scode = r[OUT::BSSI_MAX] == 1?'IC':'NC'
            payablebatch = r[OUT::BSSI_FACILITY].to_s + scode + cur_date
            header[:payablesbatch] = payablebatch

            @grid << header
      	end
        @@headerCache = @grid.dup
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
  batchid=SecureRandom.uuid
  CSV.foreach("/home/egaloustian/MongoApp1/input/concur5.csv", {:col_sep =>"|"} ) do |row|
    rec=[]
    if(row[0] != nil && row[0]=='DETAIL')
      rec[OUT::PO_NUMBER]=row[IN::PO_NUMBER]
      rec[OUT::DESCRIPTION]=row[IN::DESCRIPTION]
      rec[OUT::DOC_NUMBER]=row[IN::DOC_NUMBER]
      rec[OUT::DOC_DATE]=row[IN::DOC_DATE]
      rec[OUT::PURCHASE_AMOUNT]=row[IN::PURCHASE_AMOUNT]
      rec[OUT::DELIVERY]=row[IN::DELIVERY]
      rec[OUT::CARRIER_HANDLER]=row[IN::CARRIER_HANDLER]
      rec[OUT::BSSI_FACILITY]=row[IN::BSSI_FACILITY]
      rec[OUT::COMPANY_REQUEST_ORG]=row[IN::COMPANY_REQUEST_ORG]
      rec[OUT::JOURNAL_ACCOUNT_CODE]=row[IN::JOURNAL_ACCOUNT_CODE]
      rec[OUT::JOURNAL_AMOUNT]=row[IN::JOURNAL_AMOUNT]
      rec[OUT::DOC_TYPE]=row[IN::DOC_TYPE]
      rec[OUT::COMPANY_ALLOCATION]=row[IN::COMPANY_ALLOCATION]
      rec[OUT::DIVISION_ALLOCATION]=row[IN::DIVISION_ALLOCATION]
      rec[OUT::DEPARTMENT_ALLOCATION]=row[IN::DEPARTMENT_ALLOCATION]
      rec[OUT::REMIT_TO_ID]=row[IN::REMIT_TO_ID]
      rec[OUT::VENDOR]=row[IN::VENDOR]
      rec[OUT::BATCHID]= batchid
      rec[OUT::SHA1KEY]= getSHA1Key(row)
      rec[OUT::TAG]=true
      rec[OUT::BSSI_INTERCOMPANY]=rec[OUT::COMPANY_ALLOCATION]==rec[OUT::COMPANY_REQUEST_ORG]?0:1

      acctnum= rec[OUT::COMPANY_ALLOCATION].to_s + "-" + rec[OUT::DIVISION_ALLOCATION].to_s +
           "-" + rec[OUT::DEPARTMENT_ALLOCATION].to_s  + "-" + rec[OUT::JOURNAL_ACCOUNT_CODE].to_s
      rec[OUT::AGG_ACCOUNT] = acctnum
      rec[OUT::ACCOUNT] = acctnum
      @@allRecords << rec
    end
  end

    vouchernum = 1001
    bssi_intercompany_max=
    @@headerBuff = @@allRecords.uniq{|x|[x[OUT::SHA1KEY]]}
    @@headerBuff.each do |r|
        r[OUT::VOUCHER] = vouchernum

        @@allRecords.each do |a|
            if(r[OUT::SHA1KEY] == a[OUT::SHA1KEY])
              a[OUT::BSSI_MAX]= a[OUT::BSSI_INTERCOMPANY] | r[OUT::BSSI_INTERCOMPANY]
              a[OUT::VOUCHER] = vouchernum
            end
        end
        vouchernum+=1
    end
    @@inputBuffer = @@allRecords
    #now add the balance
    @@headerBuff = @@allRecords.uniq{|x|[x[OUT::VOUCHER]]}
    @@headerBuff.each do |r|
      rec = []
      sumbalance=0.0
      @@allRecords.each do |a|
          if(r[OUT::SHA1KEY] == a[OUT::SHA1KEY])
            rec[OUT::VOUCHER] = a[OUT::VOUCHER]
            rec[OUT::BATCHID] = a[OUT::BATCHID]
            sumbalance += a[OUT::JOURNAL_AMOUNT].to_f
          end
        end
        if(rec[OUT::VOUCHER]!=nil)
          acctnum = r[OUT::COMPANY_REQUEST_ORG] + '-000-0000-2500-25000'
          rec[OUT::AGG_ACCOUNT] = acctnum
          rec[OUT::JOURNAL_AMOUNT] = -1 * sumbalance
          @@allRecords << rec
        end

    end
    #TEMPORARY !!!
    #doMapHeader
    #doMapDetails
    #commitToDB
    #TEMPORARY !!!

end

def commitToDB
  commitInputToDB
  commitHeaderToDB
end

def commitInputToDB
  @@inputBuffer.each do |rec|
    if( rec[OUT::TAG] == true)
      inp = Input.new
      inp.PONum  = rec[OUT::PO_NUMBER]
      inp.Description = rec[OUT::DESCRIPTION]
      inp.DocNum  = rec[OUT::DOC_NUMBER]
      inp.DocDate  = rec[OUT::DOC_DATE]
      inp.PurchaseAmt  = rec[OUT::PURCHASE_AMOUNT ]
      inp.Delivery  = rec[OUT::DELIVERY]
      inp.Carrier  = rec[OUT::CARRIER_HANDLER ]
      inp.BSSI_facility  = rec[OUT::BSSI_FACILITY ]
      inp.CompanyReqOrg  = rec[OUT::COMPANY_REQUEST_ORG]
      inp.JournalAcctCode  = rec[OUT::JOURNAL_ACCOUNT_CODE ]
      inp.JournaAmt  = rec[OUT::JOURNAL_AMOUNT]
      inp.DocType  = rec[OUT::DOC_TYPE ]
      inp.CompanyAlloc  = rec[OUT::COMPANY_ALLOCATION ]
      inp.DivAlloc  = rec[OUT::DIVISION_ALLOCATION ]
      inp.DeptAlloc  = rec[OUT::DEPARTMENT_ALLOCATION ]
      inp.RemittoID  = rec[OUT::REMIT_TO_ID ]
      inp.Vendor  = rec[OUT::VENDOR]
      inp.BatchID  = rec[OUT::BATCHID]
      inp.ShaKey  = rec[OUT::SHA1KEY]
      inp.Voucher  = rec[OUT::VOUCHER]
      inp.BSSI_Intercompany  = rec[OUT::BSSI_INTERCOMPANY]
      inp.BSSI_Max  = rec[OUT::BSSI_MAX]
      inp.Account  = rec[OUT::ACCOUNT]
      inp.AggAccount  = rec[OUT::AGG_ACCOUNT ]
      inp.AggSum  = rec[OUT::AGG_SUM ]
      inp.SourceFile  = rec[OUT::SOURCE_FILE ]
      inp.save
    end
  end
end

def commitHeaderToDB
  @@inputBuffer.each do |rec|
    hdr = Header.new
    hdr.batchid = rec["batchid"]
    hdr.voucher = rec["voucher"]
    hdr.description = rec["description"]
    hdr.vendor = rec["vendor"]
    hdr.remittoid = rec["remittoid"]
    hdr.docnumber = rec["docnumber"]
    hdr.ponumber = rec["ponumber"]
    hdr.purchaseamount = rec["purchaseamount"]
    hdr.bssi_facility = rec["bssi_facility"]
    hdr.bssi_department = rec["bssi_department"]
    hdr.bssi_accountsub = rec["bssi_accountsub"]
    hdr.bssi_intercompany = rec["bssi_intercompany"]
    hdr.carrier = rec["carrier"]
    hdr.postingdate = rec["postingdate"]
    hdr.docdate = rec["docdate"]
    hdr.doctype = rec["doctype"]
    hdr.payablesbatch = rec["payablesbatch"]
    hdr.sourceFile = rec["sourceFile"]
    hdr.save
  end
end

def commitDetailsToDB
end


def getSHA1Key  (r)
  stringKey = r[IN::DOC_TYPE].to_s + r[IN::DESCRIPTION].to_s +
  r[IN::VENDOR].to_s + r[IN::REMIT_TO_ID].to_s + r[IN::DOC_DATE].to_s+
  r[IN::DOC_NUMBER].to_s  + r[IN::PO_NUMBER].to_s+
  r[IN::BSSI_FACILITY].to_s
  sh1key = Digest::SHA1.hexdigest stringKey
  return sh1key
end

def show
end

























end
