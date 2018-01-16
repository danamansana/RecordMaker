require_relative 'sql_object'

class Cat < SQLObject
  self.finalize!
end
