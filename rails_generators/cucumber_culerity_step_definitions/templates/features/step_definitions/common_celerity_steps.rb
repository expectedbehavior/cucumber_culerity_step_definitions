require 'culerity'

Before do
  $rails_server_pid ||= Culerity::run_rails(:environment => 'culerity', :port => 3001)
  $server ||= Culerity::run_server
  $browser = Culerity::RemoteBrowserProxy.new $server, {:browser => :firefox3,
    :javascript_exceptions => true,
    :resynchronize => true,
    :status_code_exceptions => true
  }
  $browser.log_level = :off
  @host = 'http://localhost:3001'
end

at_exit do
  $browser.exit if $browser
  $server.close if $server
  Process.kill(6, $rails_server_pid) if $rails_server_pid
end

Given /^I am at the "(.*)" host$/ do |hostname|
  @host = "http://#{hostname}"
end

Then /I should be at "(.*)"$/ do |hostname|  
  begin
    assert_match /#{hostname}/i, $browser.url
  rescue
    open_current_html_in_browser_
    raise
  end
end

# Before do
# #  $server ||= Culerity::run_server
# #  $browser = Culerity::RemoteBrowserProxy.new $server, {:browser => :firefox}
#   $browser.clear_cookies
#   $browser.webclient.setJavaScriptEnabled(true)
#   $upload_path = File.join(RAILS_ROOT, 'features', 'upload-files')
#   @host = 'http://localhost:41859'
# end

# at_exit do
#   $browser.exit if $browser
#   $server.close if $server
# end

When /^I go back$/ do
  $browser.back
  assert_successful_response
end

When /^I press "(.*)"$/ do |button|
  b = $browser.button(:text, button)
  print_page_on_error do
    b.html
    b.click
    assert_successful_response
  end
end

Then /^I should see a button labelled "([^\"]*)"$/ do |button_label|
  $browser.button(:value, button_label).html
end

Then /^I should see a link labelled "([^\"]*)"$/ do |link_label|
  print_page_on_error { $browser.link(:text, link_label).html }
end

Then /^I should not see a link labelled "([^\"]*)"$/ do |text|
  assert ! $browser.link(:text, text).exists?, "incorrectly found a link with text #{text}}"
end

When /^I (click|press) an image button with class "(.*)"$/ do |bogus, klass|
  $browser.button(:class, /#{Regexp.escape(klass)}/).click
  $browser.wait
  assert_successful_response
end

When /^I (click|press) an image button with name "(.*)"$/ do |bogus, name|
  $browser.button(:name, /#{Regexp.escape(name)}/).click
  $browser.wait
  assert_successful_response
end

When /^I (click|follow) "(.*)"$/ do |x, link|
  print_page_on_error do
    $browser.link(:text => /#{Regexp.escape(link)}/).click
    assert_successful_response
  end
end

When /^I (click|follow) "(.*)" (with)in class "(.*)"$/ do |x, link, y, klass|
  $browser.div(:class => /#{Regexp.escape(klass)}/).link(:text => /#{Regexp.escape(link)}/).click
  assert_successful_response
end

When /^I (click|follow) an image link (with|of) class "([^\"]*)"$/ do |x, y, klass|
  print_page_on_error { $browser.link(:class => /#{Regexp.escape(klass)}/).click }
  assert_successful_response
end

When /^I (click|follow) a link with class "([^\"]*)"$/ do |x, klass|
  $browser.link(:class => /#{Regexp.escape(klass)}/).click
  assert_successful_response
end

When /^I (click|follow) a link with id "([^\"]*)"$/ do |x, klass|
  $browser.link(:id => /#{Regexp.escape(klass)}/).click
  assert_successful_response
end

When /I fill in "(.*)" with "(.*)"/ do |field, value|
  print_page_on_error { find_field(field).set(value) }
end

def find_field(text)
  # look for the straight text, then as a substring, then case-insensative substring
  search_procs = [text, /#{Regexp.escape(text)}/, /#{Regexp.escape(text)}/i].map do |search_text|
    [:text_field, :select_list].map do |field_type| # celerity has different methods for all these things
      [
       lambda { $browser.send(field_type, :id, search_text) },
       lambda { $browser.send(field_type, :name, search_text) },
       lambda { 
         f = find_label(search_text)
         f.exists? ? $browser.send(field_type, :id, f.for) : false
       },
      ]
    end
  end.flatten
    
  search_procs.each do |l|
    e = l.call
    return e if e && e.exists?
  end
  open_current_html_in_browser_
  raise "Unable to locate field #{text}"
end

Then /^I should see "([^\"]*)" with a "([^\"]*)" field$/ do |label_name, field_type|
  assert_match field_type, find_field(label_name).attribute_value(:type)
end

When /I check "(.*)"/ do |field|
  $browser.check_box(:id, find_label(field).for).set(true)
end

Then /I should see a "(.*)" labelled "(.*)"/ do |field_type, label_text|
  print_page_on_error do
    begin
      assert $browser.send(field_type, :id, find_label(label_text).for)
    rescue
      puts "Couldn't find '#{field_type}' labelled '#{label_text}'"
      raise
    end
  end
end

When /^I uncheck "(.*)"$/ do |field|
  $browser.check_box(:id, find_label(field).for).set(false)
end

When /I select "(.*)" from "(.*)"/ do |value, field|
  print_page_on_error do
    select_list = find_field(field)
    if select_list.exists? && select_list.visible?
      select_list.select value
    else
      select_from_custom_select_list(value, field)
    end
  end
end

def select_from_custom_select_list(value, field)
  label          = find_label(field)
  new_div_id     = "new_#{label.for}"
  div            = $browser.div(:id => new_div_id)

  div.div(:class => "down_arrow").click
  
  list_container = div.ul(:class => "new_list")  
  item           = list_container.link(:text => value)
  assert list_container.visible?, "clicking on the custom combobox didn't appear to make the items appear"
  assert item.exists?,            "could not find entry in custom combobox with text '#{value}'"
  assert item.visible?,           "the entry with text '#{value}' did not become visible"

  item.click
  assert div.div(:class => "selected_text").text == value, "the selection didn't take"
  assert ! list_container.visible?,                        "the custom combobox list did not disappear"
end

When /I choose "(.*)"/ do |field|
  $browser.radio(:id, (find_label(field).for rescue field)).set(true)
end

When /^I (go to|am on|view) ([^\"]+)$/ do |x, path|
  print_page_on_error { $browser.goto @host + path_to(path) }
  assert_successful_response
end

When /I wait for the AJAX call to finish/ do
  $browser.wait
end

Then /^I should see the page title "(.*)"/ do |page_title|
  print_page_on_error { assert_equal $browser.title, page_title }
end

def elements_equal?(e1, e2)
  e1.xpath == e2.xpath rescue nil
end

def find_any_container(element, *args)
  element_methods = [:div, :p, :h1, :h2, :cell, :row]
  element_methods.each do |method|
#     result = element.send(method, *args)
    # turns out 'send' isn't exactly like calling a method.  send will hit a private method on a superclass before
    # hitting method_missing on the object itself, where calling a method normally does the opposite.
    # in this case :p was calling the print method on Object
    result = eval("element.#{method} *args")
    return result if result.exists? && !elements_equal?(result, element)
  end
  nil
end

def find_next_container(element, *args)
  if result = find_any_container(element, *args)
    find_next_container(result, *args)
  else
    element
  end
end

def find_nearest_container(*args)
  if element = find_any_container($browser, *args)
    find_next_container(element, *args)
  else
    nil
  end
end

def find_text(text)
  # if we simply check for the browser.html content we don't find content that has been added dynamically, e.g. after an ajax call
  #we are sending this into regex, so any text with regex symbols needs escaping, or it breaks
  esc_text = Regexp.escape(text)
  
  $browser.wait

  print_page_on_error do
    div = find_nearest_container(:text, /#{esc_text}/)
    div.html rescue raise("element with text '#{text}' not found")
    assert div.visible?, "element was found, but it wasn't visible"
  end
end

Then /^I should see "(.*)"$/ do |text|
  find_text text
end

Then /^I should see an image button with class "(.*)"$/ do |klass|
  button = $browser.button(:class, /#{Regexp.escape(klass)}/)
  begin
    button.html
  rescue
    open_current_html_in_browser_
    raise("link with '#{klass}' not found")
  end
end

def find_image_link_of_class(klass)
  esc_klass = Regexp.escape(klass)
  link = $browser.link(:class, /#{esc_klass}/)
end

Then /I should see an image link (with|of) class "(.*)"/ do |x, klass|
  print_page_on_error do
    find_image_link_of_class(klass).html
  end  
end 

Then /I should not see an image link (with|of) class "(.*)"/ do |x, klass|
  print_page_on_error do
    raise "image link with class '#{klass}' found" if find_image_link_of_class(klass).exists?
  end
end 

Then /I should see an image (with|of) class "(.*)"/ do |x, klass|
  esc_klass = Regexp.escape(klass)
  print_page_on_error do
    $browser.image(:class, /#{esc_klass}/).html
  end  
end 

Then /I should not see "(.*)"/ do |text|
  $browser.wait
  div = find_nearest_container(:text, /#{text}/)
  result = div.html rescue nil
  result = nil if result and !div.visible? # trying to conpensate for .div returning hidden things
  open_current_html_in_browser_ unless result.blank?
  result.should be_nil
end

Then /I should not see "(.*)" in class "(.*)"/ do |text, klass|
  div = $browser.div(:text => /#{text}/, :class => klass).html rescue nil
  open_current_html_in_browser_ unless div.blank?
  div.should be_nil
end

Then /I should see "(.*)" (with)?in class "(.*)"/ do |text, bogus, klass|
  # if we simply check for the browser.html content we don't find content that has been added dynamically, e.g. after an ajax call
  #we are sending this into regex, so any text with regex symbols needs escaping, or it breaks
  esc_text = Regexp.escape(text)
  div = $browser.div(:text, /#{esc_text}/)
  begin
    div.html
  rescue
    open_current_html_in_browser_
    raise("div with '#{text}' not found")
  end
end

Then /^I fill in the selected date for "([^"]*)" with "([^"]*)"$/ do |label_text, date|
  begin
    base_id = find_label(label_text).for
    date_obj = Date.parse(date)
    fill_in_date_fields(base_id, date_obj)
  rescue
    open_current_html_in_browser_
    raise
  end
end

# And I fill in the selected datetime for "Event Start Time" with "2020-02-02 16:15"
Then /^I fill in the selected datetime for "([^"]*)" with "([^"]*)"$/ do |label_text, datetime|
  base_id = find_label(label_text).for
  datetime_obj = DateTime.parse(datetime)
  fill_in_date_fields(base_id, datetime_obj)
  $browser.select_list(:id, base_id+'_4i').select(datetime_obj.hour)
  $browser.select_list(:id, base_id+'_5i').select(datetime_obj.min)
end

def fill_in_date_fields(element_base_id, date)
  $browser.select_list(:id, element_base_id+'_1i').select(date.year)
  $browser.select_list(:id, element_base_id+'_2i').select(Date::MONTHNAMES[date.month])
  $browser.select_list(:id, element_base_id+'_3i').select(date.day)
end


def find_label(text)
  $browser.label :text => Regexp === text ? text : /#{Regexp.escape(text)}/
end

def assert_successful_response
  status = $browser.page.web_response.status_code
  if(status == 302 || status == 301)
    location = $browser.page.web_response.get_response_header_value('Location')
    puts "Being redirected to #{location}"
    $browser.goto location
    assert_successful_response
  elsif status != 200
    open_current_html_in_browser_
    raise "Brower returned Response Code #{$browser.page.web_response.status_code}"
  end
end

When /^the current html is logged$/ do
  open_current_html_in_browser_
end

def open_current_html_in_browser_
  dir = "#{RAILS_ROOT}/public/culerity_page_errors"
  FileUtils.mkdir_p dir
  path = "#{dir}/#{Time.now.to_f.to_s}.html"
  File.open(path, "w") do |tmp|
    tmp << $browser.xml
  end
  FileUtils.cp path, "#{dir}/latest.html"
  path
end

def print_page_on_error(*args, &block)
  begin
    yield
  rescue Exception => e
    path = open_current_html_in_browser_.gsub("#{RAILS_ROOT}/public", '')
    raise e.exception(e.message + "\nPath to error html: #{@host}#{path}")
  end
end

When /^delayed job runs$/ do
#   result = Delayed::Worker.new.work_off
  result = Delayed::Job.work_off
  assert result.sum > 0, "no jobs were in the queue"
  assert result[0] > 0, "no jobs succeeded"
  assert result[1] == 0, "some jobs failed"
end

Then /^"([^\"]*)" comes before "([^\"]*)"$/ do |text_1, text_2|
  print_page_on_error do
    $browser.wait # let javascript finish modifying the page if it is
    $browser.row(:xpath => "//tr[contains(.//*,'#{text_1}')]/following-sibling::*[contains(.//*, '#{text_2}')]").html
    assert_nil $browser.row(:xpath => "//tr[contains(.//*,'#{text_2}')]/following-sibling::*[contains(.//*, '#{text_1}')]").html rescue nil
  end
end

Then /^"([^\"]*)" comes before "([^\"]*)" in "([^\"]*)"$/ do |text_1, text_2, container_id|
  esc_1 = Regexp.escape(text_1)
  esc_2 = Regexp.escape(text_2)
  print_page_on_error do
    $browser.wait # let javascript finish modifying the page if it is
    container_html = find_nearest_container(:id, container_id).html
    assert_match /#{esc_1}.*#{esc_2}/m, container_html
    assert_no_match /#{esc_2}.*#{esc_1}/m, container_html
  end
end

When /^debugger$/ do
  debugger
  1.to_s
end

Then /^I should see a header with text "([^\"]*)"$/ do |text|
  begin
    esc_text = Regexp.escape(text)
    
    found = ["h1","h2","h3","h4","h5","h6"].map do |header_tag|
      $browser.send(header_tag, :text, /#{esc_text}/).exists?
    end.any?
    assert found, "Couldn't find a header with text #{text}"
  rescue
    open_current_html_in_browser_
    raise
  end
end

When /^I sleep (.*)$/ do |num|
  sleep num.to_f
end

Then /^"([^\"]*)" should be filled with "([^\"]*)"$/ do |label_text, value|
  field = find_field(label_text)
  values = [
            (field.value rescue nil), # get value from text fields
            (field.selected_options.detect {|o| o == value} rescue nil) # get human readable text from selects
           ].compact
  assert values.include?(value), "field #{label_text.inspect} wasn't filled in with #{value.inspect}.  Instead we found: #{values.inspect}"
end

Then /^"([^\"]*)" should be disabled$/ do |label_text|
  field = find_field(label_text)
  field.disabled.should == true
end

Then /^"([^\"]*)" should not be disabled$/ do |label_text|
  field = find_field(label_text)
  field.disabled.should == false
end

Then /^I should see an image of "([^\"]*)"$/ do |src|
  $browser.image(:src, /#{Regexp.escape(src)}/)
end

#separate with commas
Then /^I should see each of "([^\"]*)"$/ do |text|
  CSV.parse_line(text).each{|x| Then %Q{I should see "#{x.strip}"}}
end

When /^I clear all the cookies$/ do
  $browser.clear_cookies
end
