require_relative 'sql_object'

class House < SQLObject
  self.finalize!
end
