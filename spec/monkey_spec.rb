require 'casset/monkey'

describe Hash do
	it "config_merge: should overwrite nil's in a with value in b recursively" do
		a = {:a => 1, :b => nil, :c => {:a => 5, :b => nil}}
		b = {:a => 3, :b => 2,   :c => {         :b => 7} }
		a.config_merge(b).should == {:a => 1, :b => 2, :c => {:a => 5, :b => 7}}
	end

	it "config_merge: should include new values from b recursively" do
		a = {:a => 1				 , :c => {:a => 5}}
		b = {:a => 2, :b => 3, :c => {:c => 3}}
		a.config_merge(b).should == {:a => 1, :b => 3, :c => {:a => 5, :c => 3}}
	end

	it "config_merge: should overwtite keys in a with those from b when instructed, recursively" do
		a = {:a => 1, :b => 2, :c => {:a => 5, :b => 6}}
		b = {:a => 3,          :c => {:a => 7,          :c => 8}}
		a.config_merge(b, :overwrite => true).should == {:a => 3, :b => 2, :c => {:a => 7, :b => 6, :c => 8}}
	end

	it "config_merge: shouldn't create new keys is no_new is passed" do
		a = {:a => nil, :c => {:a => nil}}
		b = {:a => 3,   :b => 5, :c => {:a => 4, :c => 6}, :d => 7}
		a.config_merge(b, :no_new => true).should == {:a => 3, :c => {:a => 4}}
	end

	it "config_merge: shouldn't modify the Hash it is called on" do
		a = {:a => nil, :b => {:a => nil}}
		b = {:a => 1,   :b => {:a => 2}}
		a.config_merge(b)
		a.should == {:a => nil, :b => {:a => nil}}
	end

	it "config_merge!: should overwrite nil's in a with value in b recursively" do
		a = {:a => 1, :b => nil, :c => {:a => 5, :b => nil}}
		b = {:a => 3, :b => 2,   :c => {         :b => 7} }
		a.config_merge!(b)
		a.should == {:a => 1, :b => 2, :c => {:a => 5, :b => 7}}
	end

	it "config_merge!: should include new values from b recursively" do
		a = {:a => 1				 , :c => {:a => 5}}
		b = {:a => 2, :b => 3, :c => {:c => 3}}
		a.config_merge!(b)
		a.should == {:a => 1, :b => 3, :c => {:a => 5, :c => 3}}
	end

	it "config_merge!: should overwtite keys in a with those from b when instructed, recursively" do
		a = {:a => 1, :b => 2, :c => {:a => 5, :b => 6}}
		b = {:a => 3,          :c => {:a => 7,          :c => 8}}
		a.config_merge!(b, :overwrite => true)
		a.should == {:a => 3, :b => 2, :c => {:a => 7, :b => 6, :c => 8}}
	end

	it "config_merge!: shouldn't create new keys is no_new is passed" do
		a = {:a => nil, :b => 2, :c => {:a => nil}}
		b = {:a => 3,   :b => 5, :c => {:a => 4, :c => 6}, :d => 7}
		a.config_merge!(b, :no_new => true)
		a.should == {:a => 3, :b => 2, :c => {:a => 4}}
	end
end

