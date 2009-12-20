require 'culerity'

Before do
#  $server ||= Culerity::run_server
#  $browser = Culerity::RemoteBrowserProxy.new $server, {:browser => :firefox}
  $browser.clear_cookies
  $browser.webclient.setJavaScriptEnabled(true)
  $upload_path = File.join(RAILS_ROOT, 'features', 'upload-files')
  @host = 'http://localhost:41859'
end

at_exit do
  $browser.exit if $browser
  $server.close if $server
end

When /^I go back$/ do
  $browser.back
  assert_successful_response
end

When /I press "(.*)"/ do |button|
  b = $browser.button(:text, button)
  begin
    b.html
    b.click
  rescue
    open_current_html_in_browser_
    raise
  end
  assert_successful_response
end

Then /^I should see a button labelled "([^\"]*)"$/ do |button_label|
  $browser.button(:value, button_label).html
end

Then /^I should see a link labelled "([^\"]*)"$/ do |link_label|
  $browser.link(:text, link_label).html
end

When /^I (click|press) an image button with class "(.*)"$/ do |bogus, klass|
  $browser.button(:class, /#{Regexp.escape(klass)}/).click
  assert_successful_response
end

When /^I (click|press) an image button with name "(.*)"$/ do |bogus, name|
  $browser.button(:name, /#{Regexp.escape(name)}/).click
  assert_successful_response
end

When /^I (click|follow) "(.*)"$/ do |x, link|
  begin
    $browser.link(:text => /#{Regexp.escape(link)}/).click
  rescue
    open_current_html_in_browser_
    raise
  end
  assert_successful_response
end

When /^I (click|follow) "(.*)" (with)in class "(.*)"$/ do |x, link, y, klass|
  $browser.div(:class => /#{Regexp.escape(klass)}/).link(:text => /#{Regexp.escape(link)}/).click
  assert_successful_response
end

When /^I (click|follow) an image link with class "([^\"]*)"$/ do |x, klass|
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
  begin
    find_field(field).set(value)
  rescue
    open_current_html_in_browser_
    raise
  end
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
  print_page_on_error { $browser.send(field_type, :id, find_label(label_text).for).set }
end

When /^I uncheck "(.*)"$/ do |field|
  $browser.check_box(:id, find_label(field).for).set(false)
end

When /I select "(.*)" from "(.*)"/ do |value, field|
  $browser.select_list(:id, find_label(field).for).select value
end

When /I choose "(.*)"/ do |field|
  $browser.radio(:id, (find_label(field).for rescue field)).set(true)
end

When /^I (go to|am on|view) ([^\"]+)$/ do |x, path|
  $browser.goto @host + path_to(path)
  assert_successful_response
end

When /I wait for the AJAX call to finish/ do
  $browser.wait
end

Then /^I should see the page title "(.*)"/ do |page_title|
  assert_equal $browser.title, page_title
end

Then /^I should see "(.*)"$/ do |text|
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

Then /^I should see an image button with class "(.*)"$/ do |klass|
  button = $browser.button(:class, /#{Regexp.escape(klass)}/)
  begin
    button.html
  rescue
    open_current_html_in_browser_
    raise("link with '#{klass}' not found")
  end
end

Then /I should see an image link with class "(.*)"/ do |klass|
  esc_klass = Regexp.escape(klass)
  link = $browser.link(:class, /#{esc_klass}/)
  begin
    link.html
  rescue
    open_current_html_in_browser_
    raise("link with '#{klass}' not found")
  end  
end 

Then /I should not see an image link with class "(.*)"/ do |klass|
  esc_klass = Regexp.escape(klass)
  link = $browser.link(:class, /#{esc_klass}/)
  found = false
  begin
    link.html
    found = true
  rescue
  end
  
  if found
    open_current_html_in_browser_
    raise("link with '#{klass}' found")
  end
end 

Then /I should not see "(.*)"/ do |text|
  div = $browser.div(:text, /#{text}/).html rescue nil
  open_current_html_in_browser_ unless div.blank?
  div.should be_nil
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

def open_current_html_in_browser_
  dir = "#{RAILS_ROOT}/log/culerity_page_errors"
  FileUtils.mkdir_p dir
  File.open("#{dir}/#{Time.now.to_f.to_s}.html", "w") do |tmp|
    tmp << $browser.xml
    #`open -a /Applications/Safari.app #{tmp.path}`
    puts "Path to error html: file://#{tmp.path}"
  end
end

When /^delayed job runs$/ do
  result = Delayed::Job.work_off
  assert result.sum > 0, "no jobs were in the queue"
  assert result[0] > 0, "no jobs succeeded"
  assert result[1] == 0, "some jobs failed"
end

Then /^"([^\"]*)" comes before "([^\"]*)"$/ do |text_1, text_2|
  begin
    $browser.wait # let javascript finish modifying the page if it is
    $browser.row(:xpath => "//tr[contains(.//*,'#{text_1}')]/following-sibling::*[contains(.//*, '#{text_2}')]").html
    assert_nil $browser.row(:xpath => "//tr[contains(.//*,'#{text_2}')]/following-sibling::*[contains(.//*, '#{text_1}')]").html rescue nil
  rescue
    open_current_html_in_browser_
    raise
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

When /^I click the "([^\"]*)" field$/ do |label_text|
  find_field(label_text).focus
  find_field(label_text).click
end
