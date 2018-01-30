
## Amazon Cover Size
Source: http://www.ebookcoversize.com
> "Requirements for the size of your cover art have an ideal height/width ratio of 1.6, this means a minimum of 625 pixels on the shortest side and 1000 pixels on the longest side. For best quality, your image would be 1563 pixels on the shortest side and 2500 pixels on the longest side."
- eBook Cover Size: 1563 x 2500 pixels
- File Formats: JPG, TIFF

## Problem
Source: https://kdp.amazon.com/community/thread.jspa?threadID=288939
> It's because, when you email a file to your Kindle, instead of directly loading it, it's being transferred as part of the Personal Documents Service. You will NOT get a cover on your MOBI, on a PPW, if you email it to yourself.

That's somehow vague and not true. A combo-mobi (which is produced by kindlegen >= 2.4) contains a oldschool mobi file (which is an .azw with .mobi ending in MobiDoc/KF7 format) and a azw3 file (which is in KF8 format). When sent to Kindle PDS it gets stored and the file matching your device (mostly the azw3) is served.
But sadly the azw3 file does not display its cover (it's present, it just has some display issues).
These "no cover shows up" issue may has something to do with a missing "personal documents tag", which causes the kindle to search for a cover matching die book identifier in the amazon database (which fails of course, but the fallback to the built-in cover is broken).
This theory is also very vague, since the azw3 file does so up in the personal documents section and according to some forum posts, everything transfered with sent-to-kindle is tagged as personal document automagically.
To make stuff even more confusing, when copying the combo-mobi to your kndle via USB, the contained azw3 file is choosen AND the cover is shown.

## Tools
### https://github.com/kevinhendricks/KindleUnpack
Unpack .mobi files for comparisation

### https://github.com/Sigil-Ebook/Sigil
Edit .epub files

## Kindle Personal Document Service (PDS)
- re-formats incomming files
- rumors are it's always converted to KF8
-- does not match with .azw (= KF7) files coming from p2k.co

## .mobi (old)
- .azw is deliverd via kindle-mail (?)
- is the old KF7 format (?)

## .mobi (new)
- contains the old KF7 and new KF8 format
- .azw3 is deliverd via kindle-mail
- is the new KF8 format (?)

## p2k.co
- .azw is deliverd via kindle-mail
- uses "kindlerb"
-- uses kindlegen
-- uses .opf files and directory structure to bundle .mobi files
-- maybe an old kindlegen version

## General Stuff
- see if all metadata fields are set corretly (id, author, ...)
- intercept the mail sent by p2k.co to see what he is sending before an eventual kindle-mail conversion
- have a look at the kindlegen tempfiles generated during conversion
- https://teleread.org/2017/01/29/latest-kindle-for-pc-no-longer-uses-calibre-compatible-azw-files/
- https://kindlegen.s3.amazonaws.com/docs/english/Release%20Notes.html
- Check on old kindle
- Check on fancy kindle
- try the "convert" subject
- try different kindlegen compressions
- try different cover formats/sizes
- whats this ASIN number?

## mobi (both) content
- azw3 file (new format)
-- this is in KF8 format (no cover via eMail)

- mobi file (old format)
-- this file a MobiDoc6 file
-- which is in KF7 format (covers via eMail)

## https://www.mobileread.com/forums/showthread.php?t=288964&page=6
Rename ".epub" file to ".png" and it gets converted by the kindle PDS

## https://the-digital-reader.com/2016/04/27/how-to-send-epub-to-your-kindle-by-email/
> Send a ZIP File
> For example, eReader Palace brings our attention to the fact that you can send a ZIP file to your Kindle account. In other words, you can rename the Epub file by giving it a ZIP suffix and then email the ZIP file to your Kindle account.
> Yes, that does work - to a limited degree. I've tried it, and I found that Amazon will accept the ZIP file only if you have fewer than 25 files in the ZIP file. This means that Amazon will reject more complex Epub files if they are made of too many parts.
> If that happens then your next best option will be to use calibre to convert the ebook so you can send it to your Kindle account.
The 25 files limit could be a problem, since sometimes a lot of images are included in the articles.

### https://kdp.amazon.com/community/thread.jspa?threadID=177717
> The modern mobis have 3 internal files; the "old" mobi format, K7; the "new" MOBI format, for K8, and the archival copy of the source file, which is kept in the "kindlegensrc.zip"

### https://manual.calibre-ebook.com/faq.html
> The covers for my MOBI files have stopped showing up in Kindle for PC/Kindle for Android/iPad etc.
> This is caused by a bug in the Amazon software. You can work around it by going to Preferences → Conversion → Output Options → MOBI output and setting the Enable sharing of book content option. If you are reconverting a previously converted book, you will also have to enable the option in the conversion dialog for that individual book (as per book conversion settings are saved and take precedence).
> Note that doing this will mean that the generated MOBI will show up under personal documents instead of Books on the Kindle Fire and Amazon whispersync will not work, but the covers will. It’s your choice which functionality is more important to you. I encourage you to contact Amazon and ask them to fix this bug.
> The bug in Amazon’s software is that when you put a MOBI file on a Kindle, unless the file is marked as a Personal document, Amazon assumes you bought the book from it and tries to download the cover thumbnail for it from its servers. When the download fails, it refuses to fallback to the cover defined in the MOBI file. This is likely deliberate on Amazon’s part to try to force authors to sell only through them. In other words, Kindle’s only display covers for books marked as Personal Documents or books bought directly from Amazon.
> If you send a MOBI file to an e-ink Kindle with calibre using a USB connection, calibre works around this Amazon bug by uploading a cover thumbnail itself. However, that workaround is only possible when using a USB connection and sending with calibre. Note that if you send using email, Amazon will automatically mark the MOBI file as a Personal Document and the cover will work, but the book will show up in Personal Documents.

### https://www.amazon.com/gp/sendtokindle/email
> Supported File Types:
> - Microsoft Word (.DOC, .DOCX)
> - HTML (.HTML, .HTM)
> - RTF (.RTF)
> - JPEG (.JPEG, .JPG)
> - Kindle Format (.MOBI, .AZW)
> - GIF (.GIF)
> - PNG (.PNG)
> - BMP (.BMP)
> - PDF (.PDF)

> PDFs can be converted to the Kindle format so you can take advantage of functionality such as variable font size, annotations, and Whispersync. To have a document converted to Kindle format (.azw), the subject line should be "convert" when e-mailing a personal document to your Send-to-Kindle address.

- maybe .mobi can be convert this way too
-- p2k.co does not seem to use a "convert" email subject
- maybe we can generate a .azw instead a .mobi

## azw
The AZW format is extremely similar to the MOBI format but boasts superior compression rates and also includes Amazon's own DRM. The DRM works by restricting usage of the file to the device id which is linked to the user details of the owner. A disadvantage of the format is that it does not allow for series related metadata to be added to the file.
    
## azw3
AZW3 - Kindle Format 8 (KF8) is Amazon's newer version of AZW. It supports HTML5 and CSS3 which were not supported through the standard AZW format. It has a number of other formatting options and is used by Amazon for all new Amazon eBooks. It is supported by fourth-generation Kindle devices running firmware version 4.1.0 or later and the Kindle Fire device.