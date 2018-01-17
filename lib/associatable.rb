require_relative 'searchable'
require_relative 'db_connection'
require 'active_support/inflector'


class AssocOptions
  attr_accessor(
    :name,
    :foreign_key,
    :class_name,
    :primary_key,
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options = {foreign_key: "#{name}_id".to_sym, class_name: name.to_s.capitalize.camelcase, primary_key: :id}.merge(options)
    options[:foreign_key] = "#{self_class_name.constantize.table_name}.#{options[:foreign_key]}"
    options[:primary_key] = "#{options[:class_name].constantize.table_name}.#{options[:primary_key]}"
    @name = name
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]
    @primary_key = options[:primary_key]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options = {foreign_key: "#{self_class_name.downcase}_id".to_sym, class_name: name.to_s.singularize.capitalize.camelcase, primary_key: :id}.merge(options)
    options[:foreign_key] = "#{options[:class_name].constantize.table_name}.#{options[:foreign_key]}"
    options[:primary_key] = "#{self_class_name.constantize.table_name}.#{options[:primary_key]}"
    @name = name
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]
    @primary_key = options[:primary_key]
  end
end

module Associatable

  attr_accessor :assoc_ops

  def assoc_options(options)
    @assoc_ops = self.assoc_ops || []
    @assoc_ops << options
  end

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, self.name, options)
    assoc_options(options)
    key = options.foreign_key.split(".")[1]
    define_method(options.name) do
      options.class_name.to_s.capitalize.constantize.where({options.primary_key=>self.send(key)}).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    assoc_options(options)
    key = options.primary_key.split(".")[1]
    define_method(options.name) do
      options.class_name.to_s.capitalize.constantize.where({options.foreign_key=>self.send(key)})
    end
  end



  def has_many_through_from(name, through_method, source_method)

    define_singleton_method("through_from_#{name}") {
      through = assoc_ops.select {|op| through_method == op.name}.first
      through_class = through.model_class
      source = through_class.assoc_ops.select{|op| source_method == op.name}.first
      if source
        source_class = source.model_class
        "#{self.table_name} JOIN #{through_class.table_name} ON #{through.primary_key} = #{through.foreign_key}" +
        " JOIN #{source_class.table_name} ON #{source.primary_key} = #{source.foreign_key}"
      else
        "#{self.table_name} JOIN #{through_class.table_name} ON #{self.table_name}.#{through.primary_key} = #{through.foreign_key}" +
        " JOIN #{through_class.send("through_from_#{source}".to_sym)}"
      end
    }

  end

  def has_many_through_select(name, through_method, source_method)

    define_singleton_method("through_select_#{name}") {
      through = assoc_ops.select {|op| through_method == op.name}.first
      through_class = through.model_class
      source = through_class.assoc_ops.select{|op| source_method == op.name}.first
      if source
        source_class = source.model_class
        source_class.columns.map{|col| "#{source_class.table_name}.#{col.to_s}"}.join(", ")
      else
        through_class.send("through_select_#{source_method}".to_sym)
      end
    }

  end

  def has_many_through_class(name, through_method, source_method)

    define_singleton_method("through_class_#{name}") {
      through = assoc_ops.select {|op| through_method == op.name}.first
      through_class = through.model_class
      source = through_class.assoc_ops.select{|op| source_method == op.name}.first
      if source
        source_class = source.model_class
        return source_class
      else
        through_class.send("through_class_#{source_method}".to_sym)
      end
    }

  end

  def has_many_through(name, through_method, source_method)
    has_many_through_select(name, through_method, source_method)
    has_many_through_from(name, through_method, source_method)
    has_many_through_class(name, through_method, source_method)

    define_method(name) {
    instances = DBConnection.execute(<<-SQL)
    SELECT
    #{self.class.send("through_select_#{name}".to_sym)}
    FROM
    #{self.class.send("through_from_#{name}".to_sym)}
    SQL

    instances.map{|instance| self.class.send("through_class_#{name}".to_sym).new(instance)}
    }
  end

  def has_one_through(name, through_method, source_method)
    has_many_through(name, through_method, source_method)
    define_method(name) {
      instances = DBConnection.execute(<<-SQL)
      SELECT
      #{self.class.send("through_select_#{name}".to_sym)}
      FROM
      #{self.class.send("through_from_#{name}".to_sym)}
      SQL

      instances.first
    }

  end

end

class SQLObject
  extend Associatable
end
