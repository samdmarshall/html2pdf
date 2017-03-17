all:
	clang -x objective-c -arch x86_64 -framework AppKit -framework WebKit html2pdf.m -o html2pdf
