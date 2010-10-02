Link to the latest Javascript version.

http://www.arguingwithmyself.com/demos/raycaster/#v5

Okay, let's get this straight, this guy's blog doesn't seem to have an email link so I can't contact this guy (the blog seems dead and outdated too). If you have his contact, do send a mail or issue on this git hub repo so I could at least see if it's okay if his code is ported. After all, anything on HTML/JS can be viewed since it's open-domain in most circumstances. It'll be good to see this nifty JS code gain a new lease of life with an open-source cross-platform language such as Haxe.

I've ported this guy's javascript code to Haxe to test out some features for Flash only, since conditional compiling in Haxe comes in real nifty in testing out different features. The roadmap is to create a 3d textured-version for Flash (among other stuff..), and if others may wish, develop other versions for other platforms. (JS canvas, C++, etc.). Optimisation is something I'd like to look into further here by adopting pooling of data objects and use of Alchemy memory registers for certain portions. With Haxe, this is very easy & beneficial to implement with it's inlining and built-in Alchemy opcodes for Flash.

Currently, only Flash is supported and this is just a quick test, so take a look at the source code comment headers for more info.

More info can be found here:
http://github.com/Glidias/Entropia-Raycaster/wiki/The-Algorithm-and-the-Roadmap