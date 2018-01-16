require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    whereline = params.keys.map{|key| "#{key}=?"}.join(" AND ")
    results = DBConnection.execute(<<-SQL, *params.values)
    SELECT
    *
    FROM
    #{self.table_name}
    WHERE
    #{whereline}
    SQL
    results.map {|result| self.new(result)}
  end
end

class SQLObject
  extend Searchable
end
