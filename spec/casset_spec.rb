# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'digest/md5'

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

describe Casset do
  before(:each) do
    @casset = Casset::Casset.new
		@casset.config(:root => 'spec/assets/', :dirs => {:js => 'js/'}, :cache_dir => 'cache/')
  end

	after(:each) do
		# Destroy the cache dir
		FileUtils.rm_rf('spec/assets/cache/')
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
		file = 'spec/assets/js/test.js'
		atime, mtime, new_mtime = File.atime(file), File.mtime(file), Time.new(2011, 12, 21, 17, 40, 51)
		File.utime(new_mtime, new_mtime, file)
		cache_file = @casset.render(:js, :gen_tags => false)[0]
		cache_file.should == 'spec/assets/cache/1a7ab68915f6faf6951c042bfff33e46.js'
		# Check the digest of the file contents
		Digest::MD5.file(cache_file).should == '27715488f36dec7aa0c58354d0d78aa5'
		# Set back to what they were. Might confuse stuff otherwise
		File.utime(atime, mtime, file)
	end

	it "should accept and use new parsers" do
		@casset.config(:combine => true, :min => false)
		@casset.add_parser(:js, Parser.new('js') { |file| "parsed content: #{file}" })
		@casset.js 'test.js'
		cache_file = @casset.render(:js, :gen_tags => false)[0]
		Digest::MD5.file(cache_file).should == '9e0eb26aacc7892b448c8c75922fc5cd'
	end

	it "should accept and use new minifiers" do
		@casset.config(:combine => true, :min => true)
		@casset.set_minifier(:js, Minifier.new { |file| "compressed content: #{file}" })
		@casset.js 'test.js'
		cache_file = @casset.render(:js, :gen_tags => false)[0]
		Digest::MD5.file(cache_file).should == 'ff3837b6f35ac834a484d690df4bca13'
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
		Digest::MD5.file(cache_file).should == '4424eb9f94433a1d8d144da6b8ba769b'
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
end

