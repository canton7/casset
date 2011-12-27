require 'casset/css_uri_rewriter'
include Casset

describe CssUriRewriter do
	it "should handle simple rewriting" do
		css = CssUriRewriter.rewrite("stuff\nurl(hello);\nmore stuff;", 'namespace/css/', 'public')
		css.should ==  "stuff\nurl(../namespace/css/hello);\nmore stuff;"
	end

	it "should preserve quotes" do
		css = CssUriRewriter.rewrite('url("hello")', 'css/', 'public/')
		css.should == 'url("../css/hello")'
		css = CssUriRewriter.rewrite("url('hello')", 'css/', 'public/')
		css.should == "url('../css/hello')"
	end

	it "should ignore absolute URLs of all sorts" do
		css = CssUriRewriter.rewrite('url(//hello)', 'css/', 'public/')
		css.should == 'url(//hello)'
		css = CssUriRewriter.rewrite('url(http://hello)', 'css/', 'public')
		css.should == 'url(http://hello)'
	end

	it "should ignore data URL thingies" do
		css = CssUriRewriter.rewrite('url(data:stuff)', 'css/', 'public/')
		css.should == 'url(data:stuff)'
	end

	it "should handle @imports too" do
		css = CssUriRewriter.rewrite('@import(a/thing)', 'css/', 'public')
		css.should == '@import(../css/a/thing)'
	end

	it "should correctly simplify URLs" do
		CssUriRewriter.tidy_url('a/../b/').should == 'b/'
		CssUriRewriter.tidy_url('a/../../b/').should == '../b/'
		CssUriRewriter.tidy_url('a/b/../../c/').should == 'c/'
		CssUriRewriter.tidy_url('../a/b/c/../').should == '../a/b/'
		# This *is* incorrect, but let's be incorret correctly
		CssUriRewriter.tidy_url('/../a/b/c/').should == '/../a/b/c/'
		CssUriRewriter.tidy_url('/a/../b/').should == '/b/'
		CssUriRewriter.tidy_url('a/./b/').should == 'a/b/'
		CssUriRewriter.tidy_url('./a/b/').should == 'a/b/'
		CssUriRewriter.tidy_url('/./a/b/').should == '/a/b/'
	end
end
