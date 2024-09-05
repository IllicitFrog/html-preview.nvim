package = "neoweb_preview"
version = "0.0.1"
source = {
	url = "https://github.com/Olivine-Labs/lustache/archive/v1.3.1-0.tar.gz",
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
	"pegasus",
}
build = {
	type = "builtin",
	modules = {},
}
