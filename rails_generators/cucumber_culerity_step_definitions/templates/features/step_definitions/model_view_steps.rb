When /^I view (that) ([^\"]*)$/ do |x, klass|
  var_ = instance_variable_get "@recent_#{klass.classify.gsub(/\s/,'_').downcase}"
  print_page_on_error { $browser.goto @host + polymorphic_path(var_)}
end
