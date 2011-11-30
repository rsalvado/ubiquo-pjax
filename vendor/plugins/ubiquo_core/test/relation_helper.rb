#RELATION SELECTOR ONLY TEST

def create_relation_test_model_backend

  ActiveRecord::Base.connection.create_table :test_only_models do |t|
    t.integer :test_only_model_two_id #for belongs_to with the same class name
    t.integer :arbitrary_name_id #for belongs to with different class
    #name
    t.string :name
    t.string :arbitrary_name
  end unless ActiveRecord::Base.connection.tables.include?('test_only_models')

  ActiveRecord::Base.connection.create_table :test_only_model_twos do |t|
    t.integer :test_only_model_id #for belongs_to with the same class name
    t.integer :arbitrary_name_id #for belongs to with different class
    #name
    t.string :title
    t.string :arbitrary_name
  end unless ActiveRecord::Base.connection.tables.include?('test_only_model_twos')

  ActiveRecord::Base.connection.create_table :middle_tables do |t|
    t.integer :test_only_model_id
    t.integer :test_only_model_two_id
  end unless ActiveRecord::Base.connection.tables.include?('middle_tables')

  %w{TestOnlyModel MiddleTable TestOnlyModelTwo}.each do |klass|
    Object.const_set(klass, Class.new(ActiveRecord::Base)) unless Object.const_defined? klass
  end

  set_relations
end

def set_relations options = {}
  TestOnlyModel.class_eval do
    has_many :middle_tables
    has_many :test_only_model_twos, :through => :middle_tables
    belongs_to :related, :foreign_key => :arbitrary_name_id, :class_name => TestOnlyModel.name
    belongs_to :test_only_model_two
  end

  TestOnlyModelTwo.class_eval do
    has_many :middle_tables
    has_many :test_only_models, :through => :middle_tables
    belongs_to :related, :foreign_key => :arbitrary_name_id, :class_name => TestOnlyModel.name
    belongs_to :test_only_model
  end

  MiddleTable.class_eval do
    belongs_to :test_only_model
    belongs_to :test_only_model_two
  end
end

create_relation_test_model_backend
