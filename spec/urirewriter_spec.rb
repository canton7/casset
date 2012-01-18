require 'casset/uri_rewriter'
include Casset

describe UriRewriter do
	it "should handle simple rewriting" do
		css = UriRewriter.rewrite_css("stuff\nurl(hello);\nmore stuff;", 'namespace/css/', 'public')
		css.should ==  "stuff\nurl(../namespace/css/hello);\nmore stuff;"
	end

	it "should preserve quotes" do
		css = UriRewriter.rewrite_css('url("hello")', 'css/', 'public/')
		css.should == 'url("../css/hello")'
		css = UriRewriter.rewrite_css("url('hello')", 'css/', 'public/')
		css.should == "url('../css/hello')"
	end

	it "should ignore absolute URLs of all sorts" do
		css = UriRewriter.rewrite_css('url(//hello)', 'css/', 'public/')
		css.should == 'url(//hello)'
		css = UriRewriter.rewrite_css('url(http://hello)', 'css/', 'public')
		css.should == 'url(http://hello)'
		css = UriRewriter.rewrite_css('url("/folder/img.jpg")', 'css/', 'public')
		css.should == 'url("/folder/img.jpg")'
		css = UriRewriter.rewrite_css("url('/folder/img.jpg')", 'css/', 'public')
		css.should == "url('/folder/img.jpg')"
	end

	it "should ignore data URL thingies" do
		css = UriRewriter.rewrite_css('url(data:stuff)', 'css/', 'public/')
		css.should == 'url(data:stuff)'
	end

	it "should handle @imports too" do
		css = UriRewriter.rewrite_css('@import(a/thing)', 'css/', 'public')
		css.should == '@import(../css/a/thing)'
	end

	it "should correctly simplify URLs" do
		UriRewriter.tidy_url('a/../b/').should == 'b/'
		UriRewriter.tidy_url('a/../../b/').should == '../b/'
		UriRewriter.tidy_url('a/b/../../c/').should == 'c/'
		UriRewriter.tidy_url('../a/b/c/../').should == '../a/b/'
		# This *is* incorrect, but let's be incorret correctly
		UriRewriter.tidy_url('/../a/b/c/').should == '/../a/b/c/'
		UriRewriter.tidy_url('/a/../b/').should == '/b/'
		UriRewriter.tidy_url('a/./b/').should == 'a/b/'
		UriRewriter.tidy_url('./a/b/').should == 'a/b/'
		UriRewriter.tidy_url('/./a/b/').should == '/a/b/'
	end
end
