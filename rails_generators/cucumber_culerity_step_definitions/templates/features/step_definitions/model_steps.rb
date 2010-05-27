When /^I get that ([^\"]*)$/ do |klass|
  var_name = klass.downcase.gsub(/\s/,'_')
  instance_variable_set "@recent_#{var_name}", var_name.classify.constantize.last
end

Given /^there is (a|an) ([^\"]*)$/ do |bogus, klass|
  var_name = klass.downcase.gsub(/\s/,'_')
  instance_variable_set "@recent_#{var_name}", Factory(var_name.to_sym)
end

Given /^that ([^\"]*) has "([^\"]*)" set to "([^\"]*)"$/ do |klass, field_, value|
  var_ = instance_variable_get "@recent_#{klass.classify.gsub(/\s/,'_').downcase}"
  var_.send("#{field_.gsub(/\s/,'_').downcase}=", value)
  var_.save!
end

Given /^that ([^\"]*) belongs to the "([^\"]*)" ([^\"]*)$/ do |child_klass, parent_name, parent_klass|
  child = instance_variable_get "@recent_#{child_klass.classify.gsub(/\s/,'_').downcase}"
  parent = parent_klass.classify.constantize.find_by_name(parent_name)
  child.send("#{parent_klass.downsub}=", parent)
  child.save!
end

Given /^there are ([0-9]+) ([^\"]*) with name containing "([^\"]*)"$/ do |number, klass, name|
  var_name = klass.downcase.gsub(/\s/,'_').singularize
  number.to_i.times do |i|
    create_object_with_name_using_factory(var_name, "#{name} #{i}")
  end
end

Given /^there is (a|an) ([^\"]*) whose name contains "([^\"]*)"$/ do |bogus, klass, name|
  var_name = klass.downcase.gsub(/\s/,'_')
  instance_variable_set "@recent_#{var_name}", create_object_with_name_using_factory(var_name, "#{name} #{rand(500)}")
end

Given /^there is (a|an) ([^\"]*) with ([^\"]*) "([^\"]*)"$/ do |bogus, klass, key, value|
  var_name = klass.downcase.gsub(/\s/,'_')
  instance_variable_set "@recent_#{var_name}", create_object_with_key_value_using_factory(var_name, key, value)
end

Given /^there is (a|an) ([^\"]*) named "([^\"]*)"$/ do |bogus, klass, name|
  var_name = klass.downcase.gsub(/\s/,'_')
  instance_variable_set "@recent_#{var_name}", create_object_with_name_using_factory(var_name, name)
end

def create_object_with_key_value_using_factory(klass, key, value)
  Factory(klass.to_sym, key => value)
end

def create_object_with_name_using_factory(klass, name)
  create_object_with_key_value_using_factory(klass, "name", name)
end

Given /^that ([^\"]*) belongs to that ([^\"]*)$/ do |child_klass, parent_klass|
  child = instance_variable_get "@recent_#{child_klass.classify.down_under}"
  parent = instance_variable_get "@recent_#{parent_klass.classify.down_under}"
  child.send("#{parent_klass.down_under}=", parent)
  child.save!
end
