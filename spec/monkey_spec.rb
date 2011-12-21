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
end

