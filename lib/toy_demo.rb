require_relative 'sql_object'

class Toy < SQLObject
  self.finalize!
end
