require_relative 'sql_object'

class Human < SQLObject
  self.table_name= "humans"
  self.finalize!
end
