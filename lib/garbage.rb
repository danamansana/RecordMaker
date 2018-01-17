module Associatable

  attr_accessor :assoc_ops

  def assoc_options(options)
    @assoc_ops = @assoc_options || []
    @assoc_ops << options
  end

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options(options)
    define_method(options.name) do
      options.class_name.to_s.capitalize.constantize.where({options.primary_key=>self.send(options.foreign_key)}).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.class.name, options)
    assoc_options(options)
    define_method(options.name) do
      options.class_name.to_s.capitalize.constantize.where({options.foreign_key=>self.send(options.primary_key)})
    end
  end



  def has_many_through_from(name, through_method, source_method)

    define_singleton_method("through_from_#{name}") {
      through = assoc_ops.select {|op| through_method == op.name}.first
      through_class = through.model_class
      source = through_class.assoc_ops.select{|op| source_method == op.name}.first
      if source
        source_class = source.model_class
        "#{self.table_name} JOIN #{through_class.table_name} ON #{self.table_name}.#{through.primary_key} = #{through_class.table_name}.#{through.foreign_key}" +
        " JOIN #{source_class.table_name} ON #{through_class.table_name}.#{source.primary_key} = #{source_class.table_name}.#{source.foreign_key}"
      else
        "#{self.table_name} JOIN #{through_class.table_name} ON #{self.table_name}.#{through.primary_key} = #{through_class.table_name}.#{through.foreign_key}" +
        " JOIN #{through_class.send("through_from_#{source}".to_sym)}"
      end
    }

  end

  # def has_many_through_where(name, through_method, source_method)
  #
  #   define_singleton_method("through_where_#{name}") {
  #     through = assoc_ops.select {|op| through_method == op.name}.first
  #     through_class = through.model_class
  #     source = through_class.assoc_ops.select{|op| source_method == op.name}.first
  #     if source
  #       source_class = source.model_class
  #       "#{self.table_name}.#{through.primary_key} = #{through_class.table_name}.#{through.foreign_key}" +
  #       " AND #{through_class.table_name}.#{source.primary_key} = #{source_class.table_name}.#{source.foreign_key}"
  #     else
  #       "#{self.table_name}.#{through.primary_key} = #{through_class.table_name}.#{through.foreign_key}" +
  #       " AND #{through_class.send("through_where_#{source}".to_sym)}"
  #     end
  #   }
  #
  # end

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


  def has_many_through(name, through_method, source_method)
    has_many_through_select(name, through_method, source_method)
    has_many_through_from(name, through_method, source_method)
    has_many_through_where(name, through_method, source_method)

    define_method(name) {
    instances = DBConnection.execute(<<-SQL)
    SELECT
    #{self.class.send("through_select_#{name}".to_sym)}
    FROM
    #{self.class.send("through_from_#{name}".to_sym)}
    SQL

    instances
    }
  end

end
