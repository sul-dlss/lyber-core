require 'rubygems'
require 'oci8'

class CatalogService
  def CatalogService.get_catalog_identity_for_barcode(barcode)
    connection = OCI8.new("googlefetch", "data2fetch", "//suloraprod.stanford.edu:1542/DORPRD" )

    item_query = "select
      i.CATALOG_KEY, i.CALL_SEQUENCE, i.CATEGORY1,
      c.SHELVING_KEY, c.ITEM_NUMBER, c.ANALYTIC_POSITION
      from ITEM i   join   CALLNUM c
      on i.CATALOG_KEY = c.CATALOG_KEY
      and i.CALL_SEQUENCE = c.CALL_SEQUENCE
      where i.ID = '#{barcode}'"
    item_cursor = connection.exec(item_query)
    item_data = item_cursor.fetch_hash()
    if ( not item_data)
      item_cursor.close
      connection.logoff
      raise "No item data found in catalog record for barcode: #{barcode}"
    end
    catkey = item_data['CATALOG_KEY']
    catalog_identity = {
           'catkey' => item_data['CATALOG_KEY'].round.to_s,
           'callseq' => item_data['CALL_SEQUENCE'].round.to_s,
           'bound_with' => ( item_data['CATEGORY1'] == 28 ),
           'shelving_key' => item_data['SHELVING_KEY'],
           'item_number' => item_data['ITEM_NUMBER'],
           'analytic_position' => item_data['ANALYTIC_POSITION']
    }
    item_cursor.close

    callnum_query = "select count(*) VOLUMES from CALLNUM where CATALOG_KEY = #{catkey}"
    callnum_cursor = connection.exec(callnum_query)
    callnum_data = callnum_cursor.fetch_hash()
    catalog_identity['multi_volume'] = (( callnum_data['VOLUMES'] > 1 ) and ( item_data['ANALYTIC_POSITION'] > 0))
    callnum_cursor.close

    connection.logoff
    return catalog_identity
  end
end