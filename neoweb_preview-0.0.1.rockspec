package = "neoweb_preview"
version = "0.0.1"
source = {
	url = "http://htpc:3000/cory/neoweb_preview-0.0.1.tar.gz",
	dir = "neoweb_preview-0.0.1",
}
description = {
	summary = "Web page preview for NeoVim",
	detailed = [[
    A small plugin for live web development preview
  ]],
	license = "MIT <http://opensource.org/licenses/MIT>",
}
dependencies = {
	"lua >= 5.1",
	"pegasus >= 1.0.5-0",
}
build = {
	type = "builtin",
	modules = {},
}
