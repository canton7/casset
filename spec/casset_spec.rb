# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'pp'

require 'casset'
include Casset

# Make @groups public
module Casset
	class Casset
		attr_reader :groups
	end
	class AssetGroup
		attr_reader :assets
		attr_reader :options
	end
	class Asset
		attr_reader :options
	end
end

assets_dir = 'spec/assets/'

describe Casset do
  before(:each) do
    @casset = Casset::Casset.new
		@casset.config(:root => assets_dir, :dirs => {:js => 'js/'}, :cache_dir => 'cache/')
  end

	after(:each) do
		# Destroy the cache dir
		FileUtils.rm_rf("#{assets_dir}cache/")
	end

  it "should add JS files using 1-arg syntax" do
		@casset.js 'dummy.js'
		@casset.groups[:page].assets[:js][0].should_not == nil
  end

	it "should add mutiple JS files using 1-arg syntax" do
		@casset.js ['dummy1.js', 'dummy2.js']
		@casset.groups[:page].assets[:js].length.should == 2
		@casset.groups[:page].assets[:js][0].file.should == 'dummy1.js'
		@casset.groups[:page].assets[:js][1].file.should == 'dummy2.js'
	end

	it "should correctly handle adding multiple JS files after each other" do
		@casset.js 'dummy1.js'
		@casset.js 'dummy2.js'
		@casset.groups[:page].assets[:js].length.should == 2
	end

	it "should add a JS file using 2-arg syntax with group" do
		@casset.js :group_name, 'dummy.js'
		@casset.groups[:group_name].should_not == nil
		@casset.groups[:group_name].assets[:js][0].should_not == nil
	end

	it "should add JS files using 2-arg syntax with group" do
		@casset.js :group_name, ['dummy1.js', 'dummy2.js']
		@casset.groups[:group_name].assets[:js].count.should == 2
	end

	it "should add a JS file using 2-arg syntax with options" do
		@casset.js 'dummy.js', {:min => false}
		@casset.groups[:page].assets[:js][0].should_not == nil
		@casset.groups[:page].assets[:js][0].options[:min].should == false
	end

	it "should add JS files using 2-arg syntax with options" do
		@casset.js ['dummy1.js', 'dummy2.js'], :min => false
		@casset.groups[:page].assets[:js].count.should == 2
		@casset.groups[:page].assets[:js][0].options[:min].should == false
		@casset.groups[:page].assets[:js][1].options[:min].should == false
	end

	it "should add a JS file using 3-arg syntax" do
		@casset.js :group_name, 'dummy.js', {:min => false}
		@casset.groups[:group_name].should_not == nil
		@casset.groups[:group_name].assets[:js][0].should_not == nil
		@casset.groups[:group_name].assets[:js][0].options[:min].should == false
	end

	it "should add JS files using 3-arg syntax" do
		@casset.js :group_name, ['dummy1.js', 'dummy2.js'], :min => false
		@casset.groups[:group_name].should_not == nil
		@casset.groups[:group_name].assets[:js].count.should == 2
		@casset.groups[:group_name].assets[:js][0].options[:min].should == false
		@casset.groups[:group_name].assets[:js][1].options[:min].should == false
	end

	it "should resolve namespaces correctly" do
		@casset.js 'namespace::dummy.js'
		@casset.groups[:page].assets[:js][0].options[:namespace].should == 'namespace'
	end

	it "should complain if asked to render a nonexistent asset" do
		@casset.js 'dummy.js'
		expect{ @casset.render(:js) }.to raise_error(Errno::ENOENT)
	end

	it "should return the correct link to a file if not minifying or combining" do
		@casset.config(:combine => false, :min => false)
		@casset.js 'test.js'
		@casset.render(:js).should == '<script type="text/javascript" src="js/test.js"></script>'
	end

	it "should return a valid file if combining but not minifying" do
		@casset.config(:combine => true, :min => false)
		@casset.js ['test.js', 'test2.js']
		# Set the mtime of the file to a known, test state
		files = ["#{assets_dir}js/test.js", "#{assets_dir}js/test2.js"]
		times = files.inject([]){ |s, f| s << {:file => f, :atime => File.atime(f), :mtime => File.mtime(f)} }	
		new_mtime = Time.new(2011, 12, 21, 17, 40, 51)
		files.each{ |f| File.utime(new_mtime, new_mtime, f) }
		cache_file = @casset.render(:js, :gen_tags => false)[0]
		cache_file.should == "#{assets_dir}cache/9c85ee0a70fcf72e8b4daf986c22a3fe.js"
		# Check the digest of the file contents
		FileUtils.compare_file(cache_file, "#{assets_dir}results/combine_no_min.js").should == true
		# Set back to what they were. Might confuse stuff otherwise
		times.each{ |t| File.utime(t[:atime], t[:mtime], t[:file]) }
	end

	it "should accept and use new parsers" do
		@casset.config(:combine => true, :min => false)
		@casset.add_parser(:js, Parser.new('js') { |file| "parsed content: #{file}" })
		@casset.js 'test.js'
		cache_file = @casset.render(:js, :gen_tags => false)[0]
		FileUtils.compare_file(cache_file, "#{assets_dir}results/new_parsers.js").should == true
	end

	it "should accept and use new minifiers" do
		@casset.config(:combine => true, :min => true)
		@casset.set_minifier(:js, Minifier.new { |file| "compressed content: #{file}" })
		@casset.js 'test.js'
		cache_file = @casset.render(:js, :gen_tags => false)[0]
		FileUtils.compare_file(cache_file, "#{assets_dir}results/new_minifiers.js").should == true
	end

	it "should handle remote URLS correctly" do
		@casset.config(:combine => true, :min => true)
		@casset.js 'http://test_asset'
		@casset.render(:js, :gen_tags => false)[0].should == 'http://test_asset'
	end

	it "shouldn't link straight to file if instructed not to" do
		@casset.config(:combine => false, :min => false, :retain_filename => false)
		@casset.js 'test.js'
		@casset.render(:js, :gen_tags => false)[0].should_not == 'js/test.js'
	end

	it "should render filenames before tag when instructed to" do
		@casset.config(:combine => true, :min => false, :show_filenames_before => true)
		@casset.js 'test.js'
		@casset.render(:js).start_with?('<!-- File contains:').should be_true
	end

	it "should render filenames inside cache when instructed to" do
		@casset.config(:combine => true, :min => false, :show_filenames_inside => true)
		@casset.js 'test.js'
		cache_file = @casset.render(:js, :gen_tags => false)[0]
		FileUtils.compare_file(cache_file, "#{assets_dir}results/filenames_inside.js").should == true
	end

	it "should allow creation of groups using add_group" do
		@casset.add_group(:test_group, :js => ['test1.js', 'test2.js'], :css => 'test.js', :enable => false)
		@casset.groups.should include(:test_group)
		@casset.groups[:test_group].assets[:js].length.should == 2
		@casset.groups[:test_group].assets[:css].length.should == 1
		@casset.groups[:test_group].options[:enable].should == false
	end

	it "should refuse to set group settings if the group doesn't exist" do
		expect{ @casset.group_options(:testy, {}) }.to raise_error
	end

	it "should set group settings if the group does exist" do
		@casset.add_group(:test_group, :enable => true)
		@casset.group_options(:test_group, :enable => false)
		@casset.groups[:test_group].options[:enable].should == false
	end

	it "should enable new groups by default" do
		@casset.js :new_group, 'test.js'
		@casset.groups[:new_group].options[:enable].should == true
		@casset.add_group(:new_group2)
		@casset.groups[:new_group].options[:enable].should == true
	end

	it "sould resolve deps correctly" do
		@casset.config(:combine => false, :min => false)
		@casset.add_group(:group2, :js => 'test2.js', :depends_on => [:group1])
		@casset.js :group1, 'test.js'
		# Must render these in the right order
		@casset.render(:js, :gen_tags => false).should == ['js/test.js', 'js/test2.js']
		# If we disable group1, if should be rendered anyway
		@casset.group_options(:group1, :enable => false)
		@casset.render(:js, :gen_tags => false).should == ['js/test.js', 'js/test2.js']
	end

	it "should handle tag attributes correctly" do
		@casset.config(:combine => false, :min => false)
		@casset.add_group(:group, :js => 'test.js', :attr=>{:js => {'key' => 'value'}})
		@casset.render(:js).should =~ /<script.*key="value".*><\/script>/
	end

	it "should correctly clear out cached assets" do
		@casset.js 'test.js'
		cache_file = @casset.render(:js, :gen_tags => false)[0]
		# Shouldn't delete if it we specify CSS files only
		@casset.clear_cache(:css)
		File.exist?(cache_file).should == true
		# Shouldn't delete it if we ask for all files before <an early date>
		@casset.clear_cache(:all, :before => Time.new(1970, 1, 1, 0, 0, 0))
		File.exist?(cache_file).should == true
		# Should delete it if we ask for all js files since now
		@casset.clear_cache(:js, :before => Time.now)
		File.exist?(cache_file).should == false
	end
end

