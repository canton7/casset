require 'casset/monkey'

describe Hash do
	it "should overwrite nil's in a with value in b recursively" do
		a = {:a => 1, :b => nil, :c => {:a => 5, :b => nil}}
		b = {:a => 3, :b => 2,   :c => {         :b => 7} }
		a.config_merge(b).should == {:a => 1, :b => 2, :c => {:a => 5, :b => 7}}
	end

	it "should include new values from b recursively" do
		a = {:a => 1				 , :c => {:a => 5}}
		b = {:a => 2, :b => 3, :c => {:c => 3}}
		a.config_merge(b).should == {:a => 1, :b => 3, :c => {:a => 5, :c => 3}}
	end

	it "should overwtite keys in a with those from b when instructed, recursively" do
		a = {:a => 1, :b => 2, :c => {:a => 5, :b => 6}}
		b = {:a => 3,          :c => {:a => 7,          :c => 8}}
		a.config_merge(b, :overwrite => true).should == {:a => 3, :b => 2, :c => {:a => 7, :b => 6, :c => 8}}
	end

	it "shouldn't create new keys is no_new is passed" do
		a = {:a => nil, :c => {:a => nil}}
		b = {:a => 3,   :b => 5, :c => {:a => 4, :c => 6}, :d => 7}
		a.config_merge(b, :no_new => true).should == {:a => 3, :c => {:a => 4}}
	end

	it "shouldn't modify the Hash it is called on" do
		a = {:a => nil, :b => {:a => nil}}
		b = {:a => 1,   :b => {:a => 2}}
		a.config_merge(b)
		a.should == {:a => nil, :b => {:a => nil}}
	end

	it "should obey :no_new when the value in question is an empty hash" do
		a = {:a => 1, :b => {}, :c => {:a => 3, :b => {}}}
		b = {:b => {:a => 3},   :c => {:a => 4, :b => {:a => 5}}}
		a.config_merge(b).should == {:a => 1, :b => {:a => 3}, :c => {:a => 3, :b => {:a => 5}}}
	end

	it "should handle the bang variant properly" do
		a = {:a => 1, :b => nil, :c => {:a => 5, :b => nil}}
		b = {:a => 3, :b => 2,   :c => {         :b => 7} }
		a.config_merge!(b)
		a.should == {:a => 1, :b => 2, :c => {:a => 5, :b => 7}}
	end

	it "should merge procs" do
		a = {:a => nil}
		b = {:a => Proc.new { 'abc' }}
		a.config_merge(b)[:a].call.should == 'abc'
	end

	it "should have no_new and overwrite properly" do
		a = {:a => nil, :b => 3, :c => {:a => nil, :b => 2, :d => 5}, :e => 2}
		b = {:a => 4,   :b => 5, :c => {:a => 6,   :b => 7, :c => 8}, :d => 9}
		a.config_merge(b, :no_new => true, :overwrite => true).should == {:a => 4, :b => 5, :c => {:a => 6, :b => 7, :d => 5}, :e => 2}
	end

	it "should merge arrays correctly" do
		a = {:a => nil, :b => [], :c => [:a, :b]}
		b = {:a => 4, :b => [:a, :b, :c], :c => [:c]}
		a.config_merge(b).should == {:a => 4, :b => [:a, :b, :c], :c => [:a, :b, :c]}
	end

	it "should merge arrays correctly with overwrite" do
		a = {:a => nil, :b => [:a]}
		b = {:a => 4, :b => [:b, :c]}
		a.config_merge(b, :overwrite => true).should == {:a => 4, :b => [:b, :c]}
	end

	it "should resolve procs" do
		a = {:a => {:b => Proc.new{ false }}}
		a.resolve_procs!.should == {:a => {:b => false}}
	end

	it "should resolve lambdas" do
		a = {:a => {:b => lambda { return false }}}
		a.resolve_procs!.should == {:a => {:b => false}}
	end
end

