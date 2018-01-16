require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.table_name=(table_name= self.name.tableize)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.tableize
  end

  def self.columns
    @query ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @query.first.map{|string| string.to_sym}

  end

  def attributes
    instance_variable_get('@attributes') || instance_variable_set('@attributes', {})
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) { attributes[column] }
      define_method("#{column}=") {|arg| attributes[column] = arg}
    end
  end

  def initialize(params = {})

    cols = self.class.columns
    params.each do |name, value|
      namesym = "#{name}=".to_sym
      raise "unknown attribute '#{name}'" unless cols.include?(name.to_sym)
      # atts[name] = value
      self.send(namesym, value)
    end

  end

  def self.all

    instances = DBConnection.execute(<<-SQL)
    SELECT
    *
    FROM
    #{self.table_name}
    SQL

    parse_all(instances)
  end

  def self.parse_all(results)
    results.map {|result| self.new(result)}
  end

  def self.find(id)
    item = DBConnection.execute(<<-SQL)
    SELECT
    *
    FROM
    #{self.table_name}
    WHERE
    id=#{id}
    SQL
    parse_all(item).first
  end

  def insert
    cols = self.attributes.keys.map{|el| el.to_s}.join(",")
    vals = self.attributes.values
    qs = vals.map{'?'}.join(",")
    DBConnection.execute(<<-SQL, *vals)
    INSERT INTO
    #{self.class.table_name} (#{cols})
    VALUES
    (#{qs})
    SQL
    self.id= DBConnection.last_insert_row_id
  end

  def update
    col_command = self.class.columns.map{|col| "#{col}=?"}.join(",")
    DBConnection.execute(<<-SQL, *self.attributes.values, self.id)
    UPDATE
    #{self.class.table_name}
    SET
    #{col_command}
    WHERE
    id=?
    SQL
  end

  def save

    if self.id.nil?
      insert
    else
      update
    end
  end

end
