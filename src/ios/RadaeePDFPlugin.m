//
//  AlmaZBarReaderViewController.h
//  Paolo Messina
//
//  Created by Paolo Messina on 06/07/15.
//
//

#import "RadaeePDFPlugin.h"
#import "RDPDFViewController.h"
#import "PDFHttpStream.h"

#pragma mark - Synthesize

@interface RadaeePDFPlugin() <RDPDFViewControllerDelegate>

@end

@implementation RadaeePDFPlugin
@synthesize cdv_command;

#pragma mark - Cordova Plugin

+ (RadaeePDFPlugin *)pluginInit
{
    RadaeePDFPlugin *r = [[RadaeePDFPlugin alloc] init];
    [r pluginInitialize];
    
    return r;
}

- (void)pluginInitialize
{
    inkColor = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"InkColor"];
    rectColor = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"RectColor"];
    underlineColor = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"UnderlineColor"];
    strikeoutColor = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"StrikeoutColor"];
    highlightColor = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"HighlightColor"];
    ovalColor = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"OvalColor"];
    selColor = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"SelColor"];
}

#pragma mark - Plugin API

- (void)show:(CDVInvokedUrlCommand*)command;
{
    self.cdv_command = command;
    
    // Get user parameters
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    url = [params objectForKey:@"url"];
    if([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]){
        
        NSString *cacheFile = [[NSTemporaryDirectory() stringByAppendingString:@""] stringByAppendingString:@"cacheFile.pdf"];
        
        PDFHttpStream *httpStream = [[PDFHttpStream alloc] init];
        [httpStream open:url :cacheFile];
        
        [self readerInit];
        
        int result = [m_pdf PDFOpenStream:httpStream :[params objectForKey:@"password"]];
        
        NSLog(@"%d", result);
        if(result != err_ok && result != err_open){
            [self pdfChargeDidFailWithError:@"Error open pdf" andCode:(NSInteger) result];
        }
        
        [self showReader];
        
    } else {
        if ([url containsString:@"file://"]) {
            
            NSString *filePath = [url stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                filePath = [documentsDirectory stringByAppendingPathComponent:filePath];
            }
            
            [self openPdf:filePath withPassword:[params objectForKey:@"password"]];
        } else {
            [self openFromPath:command];
        }
    }
    
}

- (void)openFromAssets:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    // Get user parameters
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    url = [params objectForKey:@"url"];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:url ofType:nil];

    [self openPdf:filePath withPassword:[params objectForKey:@"password"]];
}

- (void)openFromPath:(CDVInvokedUrlCommand *)command
{
    // Get user parameters
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    url = [params objectForKey:@"url"];
    
    NSString *filePath = url;
    
    [self openPdf:filePath withPassword:[params objectForKey:@"password"]];
}

- (void)openPdf:(NSString *)filePath withPassword:(NSString *)password
{
    NSLog(@"File Path: %@", filePath);
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self pdfChargeDidFailWithError:@"File not exist" andCode:200];
        return;
    }
    
    _lastOpenedPath = filePath;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"fileStat"];
    
    [self readerInit];
    
    int result = [m_pdf PDFOpen:filePath :password];
    
    NSLog(@"%d", result);
    if(result != err_ok && result != err_open){
        [self pdfChargeDidFailWithError:@"Error open pdf" andCode:(NSInteger) result];
    }
    
    [self showReader];
}


- (void)activateLicense:(CDVInvokedUrlCommand *)command
{
    [self pluginInitialize];
    
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    [[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:@"actBundleId"];
    [[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"company"] forKey:@"actCompany"];
    [[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"email"] forKey:@"actEmail"];
    [[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"key"] forKey:@"actSerial"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[[params objectForKey:@"licenseType"] intValue]] forKey:@"actActivationType"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    APP_Init();
    
    [self activateLicenseResult:[[NSUserDefaults standardUserDefaults] boolForKey:@"actIsActive"]];
}

- (void)fileState:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_lastOpenedPath]) {
        
        NSString *message = @"";
        
        switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"fileStat"]) {
            case 0:
            message = @"File has not been modified.";
            break;
            
            case 1:
            message = @"File has been modified but not saved.";
            break;
            
            case 2:
            message = @"File has been modified and saved.";
            break;
            
            default:
            break;
        }
        
        [self getFileStateResult:message];
    }
    else
        [self fileStateDidFailWithError:@"File not found"];
}

- (void)getPageNumber:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    if (m_pdf == nil || [m_pdf getDoc] == nil) {
        [self getPageNumberDidFailWithError:@"Error in pdf instance"];
        return;
    }
    
    int page = [m_pdf getCurrentPage];
    [self getPageNumberResult:[NSString stringWithFormat:@"%i", page]];
}

- (void)setThumbnailBGColor:(CDVInvokedUrlCommand*)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    thumbBackgroundColor = [[params objectForKey:@"color"] intValue];
}

- (void)setThumbGridBGColor:(CDVInvokedUrlCommand*)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    gridBackgroundColor = [[params objectForKey:@"color"] intValue];
}

- (void)setReaderBGColor:(CDVInvokedUrlCommand*)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    readerBackgroundColor = [[params objectForKey:@"color"] intValue];
}

- (void)setThumbGridElementHeight:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    gridElementHeight = [[params objectForKey:@"height"] floatValue];
}

- (void)setThumbGridGap:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    gridGap = [[params objectForKey:@"gap"] floatValue];
}

- (void)setThumbGridViewMode:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    gridMode = [[params objectForKey:@"mode"] floatValue];
}

- (void)setTitleBGColor:(CDVInvokedUrlCommand*)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    titleBackgroundColor = [[params objectForKey:@"color"] intValue];
}

- (void)setIconsBGColor:(CDVInvokedUrlCommand*)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    iconsBackgroundColor = [[params objectForKey:@"color"] intValue];
}

- (void)setThumbHeight:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    thumbHeight = [[params objectForKey:@"height"] floatValue];
}

- (void)setFirstPageCover:(CDVInvokedUrlCommand*)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    firstPageCover = [[params objectForKey:@"cover"] boolValue];
}

- (void)setDoubleTapZoomMode:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    doubleTapZoomMode = [[params objectForKey:@"mode"] intValue];
}

- (void)setImmersive:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
 
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    isImmersive = [[params objectForKey:@"immersive"] boolValue];
    
    if (m_pdf != nil && [m_pdf getDoc] != nil) {
        [m_pdf setImmersive:isImmersive];
    }
}

- (void)readerInit
{
    if( m_pdf == nil )
    {
        m_pdf = [[RDPDFViewController alloc] initWithNibName:@"RDPDFViewController" bundle:nil];
    }
    
    [m_pdf setDelegate:self];
    
    [self setPagingEnabled:YES];
    [self setDoublePageEnabled:YES];
    
    [m_pdf setFirstPageCover:firstPageCover];
    [m_pdf setDoubleTapZoomMode:doubleTapZoomMode];
    [m_pdf setImmersive:NO];
    
    [m_pdf setViewModeImage:[UIImage imageNamed:@"btn_view.png"]];
    [m_pdf setSearchImage:[UIImage imageNamed:@"btn_search.png"]];
    [m_pdf setLineImage:[UIImage imageNamed:@"btn_annot_ink.png"]];
    [m_pdf setRectImage:[UIImage imageNamed:@"btn_annot_rect.png"]];
    [m_pdf setEllipseImage:[UIImage imageNamed:@"btn_annot_ellipse.png"]];
    [m_pdf setOutlineImage:[UIImage imageNamed:@"btn_outline.png"]];
    [m_pdf setPrintImage:[UIImage imageNamed:@"btn_print.png"]];
    [m_pdf setGridImage:[UIImage imageNamed:@"btn_grid.png"]];
    
    [m_pdf setRemoveImage:[UIImage imageNamed:@"annot_remove.png"]];
    
    [m_pdf setPrevImage:[UIImage imageNamed:@"btn_left.png"]];
    [m_pdf setNextImage:[UIImage imageNamed:@"btn_right.png"]];
    
    [m_pdf setPerformImage:[UIImage imageNamed:@"btn_perform.png"]];
    [m_pdf setDeleteImage:[UIImage imageNamed:@"btn_remove.png"]];
    
    [m_pdf setDoneImage:[UIImage imageNamed:@"btn_done.png"]];
    
    [m_pdf setHideGridImage:YES];
    
    if (disableToolbar) {
        [m_pdf setHideLineImage:YES];
        [m_pdf setHideRectImage:YES];
        [m_pdf setHidePrintImage:YES];
        [m_pdf setHideSearchImage:YES];
        [m_pdf setHideEllipseImage:YES];
        [m_pdf setHideOutlineImage:YES];
        [m_pdf setHideBookmarkImage:YES];
        [m_pdf setHideViewModeImage:YES];
        [m_pdf setHideBookmarkListImage:YES];
    } else {
        [m_pdf setHideLineImage:NO];
        [m_pdf setHideRectImage:NO];
        [m_pdf setHidePrintImage:NO];
        [m_pdf setHideSearchImage:NO];
        [m_pdf setHideEllipseImage:NO];
        [m_pdf setHideOutlineImage:NO];
        [m_pdf setHideBookmarkImage:NO];
        [m_pdf setHideViewModeImage:NO];
        [m_pdf setHideBookmarkListImage:NO];
    }
    
    /*
     SetColor, Available features
     
     0: inkColor
     1: rectColor
     2: underlineColor
     3: strikeoutColor
     4: highlightColor
     5: ovalColor
     6: selColor
     
     */
    
    [self setColor:0xFF000000 forFeature:0];
    [self setColor:0xFF000000 forFeature:1];
    [self setColor:0xFF000000 forFeature:2];
    [self setColor:0xFF000000 forFeature:3];
    [self setColor:0xFFFFFF00 forFeature:4];
    [self setColor:0xFF000000 forFeature:5];
    [self setColor:0x400000C0 forFeature:6];
    
    [self loadSettingsWithDefaults];
}

- (void)showReader
{
    [self pdfChargeDidFinishLoading];
    
    //toggle thumbnail/seekbar
    if (bottomBar < 1){
        [m_pdf setThumbHeight:(thumbHeight > 0) ? thumbHeight : 50];
        [m_pdf PDFThumbNailinit:1];
        [m_pdf setThumbnailBGColor:thumbBackgroundColor];
    }
    else
        [m_pdf PDFSeekBarInit:1];
    
    [m_pdf setReaderBGColor:readerBackgroundColor];
    
    //Set thumbGridView
    [m_pdf setThumbGridBGColor:gridBackgroundColor];
    [m_pdf setThumbGridElementHeight:gridElementHeight];
    [m_pdf setThumbGridGap:gridGap];
    [m_pdf setThumbGridViewMode:gridMode];
    
    m_pdf.hidesBottomBarWhenPushed = YES;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:m_pdf];
    
    if (titleBackgroundColor != 0) {
        navController.navigationBar.barTintColor = UIColorFromRGB(titleBackgroundColor);
    }
    
    if (iconsBackgroundColor != 0) {
        navController.navigationBar.tintColor = UIColorFromRGB(iconsBackgroundColor);
    }
    
    [navController.navigationBar setTranslucent:NO];
    
    [self.viewController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Settings

- (void)toggleThumbSeekBar:(int)mode
{
    bottomBar = mode;
}

- (void)setPagingEnabled:(BOOL)enabled
{
    g_paging_enabled = enabled;
}

- (void)setDoublePageEnabled:(BOOL)enabled
{
    g_double_page_enabled = enabled;
}

- (void)setReaderViewMode:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    int mode = [[params objectForKey:@"mode"] intValue];
    
    if (mode > 0 && mode < 5) {
        _viewMode = mode;
    }
}

- (void)setToolbarEnabled:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    BOOL enabled = [[params objectForKey:@"enabled"] boolValue];
    
    disableToolbar = !enabled;
}

- (void)setColor:(int)color forFeature:(int)feature
{
    switch (feature) {
        case 0:
            inkColor = color;
            break;
            
        case 1:
            rectColor = color;
            break;
            
        case 2:
            underlineColor = color;
            break;
            
        case 3:
            strikeoutColor = color;
            break;
            
        case 4:
            highlightColor = color;
            break;
            
        case 5:
            ovalColor = color;
            break;
            
        case 6:
            selColor = color;
            break;
            
        default:
            break;
    }
}

#pragma mark - Init defaults

- (void)loadSettingsWithDefaults
{
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"CaseSensitive"];
    [[NSUserDefaults standardUserDefaults] setFloat:2.0f forKey:@"InkWidth"];
    [[NSUserDefaults standardUserDefaults] setFloat:2.0f forKey:@"RectWidth"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.15f forKey:@"SwipeSpeed"];
    [[NSUserDefaults standardUserDefaults] setFloat:1.0f forKey:@"SwipeDistance"];
    [[NSUserDefaults standardUserDefaults] setInteger:1.0f forKey:@"RenderQuality"];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"MatchWholeWord"];
    [[NSUserDefaults standardUserDefaults] setInteger:inkColor forKey:@"InkColor"];
    [[NSUserDefaults standardUserDefaults] setInteger:rectColor forKey:@"RectColor"];
    [[NSUserDefaults standardUserDefaults] setInteger:underlineColor forKey:@"UnderlineColor"];
    [[NSUserDefaults standardUserDefaults] setInteger:strikeoutColor forKey:@"StrikeoutColor"];
    [[NSUserDefaults standardUserDefaults] setInteger:highlightColor forKey:@"HighlightColor"];
    [[NSUserDefaults standardUserDefaults] setInteger:ovalColor forKey:@"OvalColor"];
    [[NSUserDefaults standardUserDefaults] setInteger:_viewMode forKey:@"DefView"];
    [[NSUserDefaults standardUserDefaults] setInteger:selColor forKey:@"SelColor"];
    
    g_def_view = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"DefView"];
    g_MatchWholeWord = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"MatchWholeWord"];
    
    g_rect_color = rectColor;
    g_ink_color = inkColor;
    g_sel_color = selColor;
    g_oval_color = ovalColor;
    annotHighlightColor = highlightColor;
    annotUnderlineColor = underlineColor;
    annotStrikeoutColor = strikeoutColor;
    //annotSquigglyColor = 0xFF00FF00;
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - load Bookmarks

+ (NSMutableArray *)loadBookmark
{
    return [self loadBookmarkForPdf:@""];
}

+ (NSMutableArray *)loadBookmarkForPdf:(NSString *)pdfName
{
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *dpath=[paths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    return [RadaeePDFPlugin addBookMarks:dpath :@"" :fm :0 pdfName:pdfName];
}

+ (NSMutableArray *)addBookMarks:(NSString *)dpath :(NSString *)subdir :(NSFileManager *)fm :(int)level pdfName:(NSString *)pdfName
{
    NSMutableArray *bookmarks = [NSMutableArray array];
    
    NSDirectoryEnumerator *fenum = [fm enumeratorAtPath:dpath];
    NSString *fName;
    while(fName = [fenum nextObject])
    {
        
        NSString *dst = [dpath stringByAppendingFormat:@"/%@",fName];
        NSString *tempString ;
        
        if(fName.length >10)
        {
            tempString = [fName substringFromIndex:fName.length-9];
        }
        
        if( [tempString isEqualToString:@".bookmark"] )
        {
            if (pdfName.length > 0 && ![fName containsString:pdfName]) {
                continue;
            }
            
            //add to list.
            NSFileHandle *fileHandle =[NSFileHandle fileHandleForReadingAtPath:dst];
            NSString *content = [[NSString alloc]initWithData:[fileHandle availableData] encoding:NSUTF8StringEncoding];
            NSArray *myarray =[content componentsSeparatedByString:@","];
            [myarray objectAtIndex:0];
            NSArray *arr = [[NSArray alloc] initWithObjects:[myarray objectAtIndex:0],[myarray objectAtIndex:1],[myarray objectAtIndex:2],[myarray objectAtIndex:3],[myarray objectAtIndex:4],dst,nil];
            [bookmarks addObject:arr];
        }
    }
    
    return bookmarks;
}
#pragma mark - Delegate Methods

- (void)activateLicenseResult:(BOOL)success
{
    if (success) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult
                                                resultWithStatus:CDVCommandStatus_OK
                                                messageAsString:@"License activated"] callbackId:[self.cdv_command callbackId]];
    }
    else
    {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"License NOT activated"] callbackId:[self.cdv_command callbackId]];
    }
}

- (void)chargePdfSendResult:(CDVPluginResult*)result
{
    //m_pdf = nil;
    [self.commandDelegate sendPluginResult:result callbackId: [self.cdv_command callbackId]];
}

- (void)pdfChargeDidFinishLoading
{
    [self chargePdfSendResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"Pdf Succesfully charged"]];
}

- (void)pdfChargeDidFailWithError:(NSString*)errorMessage andCode:(NSInteger)statusCode{
    //if(m_pdf)
    //[m_pdf dismissViewControllerAnimated:YES completion:nil];
    NSDictionary *dict = @{@"errorMessage" : errorMessage, @"statusCode" : [NSNumber numberWithInteger:statusCode]};
    [self chargePdfSendResult:[CDVPluginResult
                               resultWithStatus: CDVCommandStatus_ERROR
                               messageAsDictionary:dict]];
}
    
- (void)getFileStateResult:(NSString *)message
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message] callbackId:[self.cdv_command callbackId]];
}
    
- (void)fileStateDidFailWithError:(NSString *)errorMessage
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage] callbackId:[self.cdv_command callbackId]];
}

- (void)getPageNumberResult:(NSString *)message
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message] callbackId:[self.cdv_command callbackId]];
}

- (void)getPageNumberDidFailWithError:(NSString *)errorMessage
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage] callbackId:[self.cdv_command callbackId]];
}

- (void)JSONFormFieldsResult:(NSString *)message
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message] callbackId:[self.cdv_command callbackId]];
}

- (void)JSONFormFieldsAtPageResult:(NSString *)message
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message] callbackId:[self.cdv_command callbackId]];
}

- (void)setFormFieldsResult
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:[self.cdv_command callbackId]];
}

- (void)setFormFieldsDidFailWithError:(NSString *)errorMessage
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage] callbackId:[self.cdv_command callbackId]];
}

#pragma mark - Form Extractor

- (void)JSONFormFields:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    
    RDFormManager *fe = [[RDFormManager alloc] initWithDoc:[m_pdf getDoc]];
    
    [self JSONFormFieldsResult:[fe jsonInfoForAllPages]];
}

- (void)JSONFormFieldsAtPage:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    RDFormManager *fe = [[RDFormManager alloc] initWithDoc:[m_pdf getDoc]];
    
    [self JSONFormFieldsAtPageResult:[fe jsonInfoForPage:(int)[params objectForKey:@"page"]]];
}

- (void)setFormFieldWithJSON:(CDVInvokedUrlCommand *)command
{
    self.cdv_command = command;
    NSDictionary *params = (NSDictionary*) [cdv_command argumentAtIndex:0];
    
    RDFormManager *fe = [[RDFormManager alloc] initWithDoc:[m_pdf getDoc]];
    
    NSError *error;
    if ([params objectForKey:@"json"]) {
        [fe setInfoWithJson:[params objectForKey:@"json"] error:&error];
        
        if (error) {
            [self setFormFieldsDidFailWithError:[error description]];
        } else
        {
            if (m_pdf) {
                [m_pdf refreshCurrentPage];
            }
            [self setFormFieldsResult];
        }
    } else
    {
        [self setFormFieldsDidFailWithError:@"JSON not found"];
    }
}

#pragma mark - Reader Delegate

- (void)willShowReader
{
    if (_delegate) {
        [_delegate willShowReader];
    }
}

- (void)didShowReader
{
    if (_delegate) {
        [_delegate didShowReader];
    }
}

- (void)willCloseReader
{
    if (_delegate) {
        [_delegate willCloseReader];
    }
}

- (void)didCloseReader
{
    if (_delegate) {
        [_delegate didCloseReader];
    }
}

- (void)didChangePage:(int)page
{
    if (_delegate) {
        [_delegate didChangePage:page];
    }
}

- (void)didSearchTerm:(NSString *)term found:(BOOL)found
{
    if (_delegate) {
        [_delegate didSearchTerm:term found:found];
    }
}

#pragma mark - Path Utils

- (NSString *)getCustomPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [paths objectAtIndex:0];
    NSString *customDirectory = [libraryPath stringByAppendingPathComponent:@"customDirectory"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:customDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:customDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return customDirectory;
}

- (BOOL)moveFileToCustomDir:(NSString *)path overwrite:(BOOL)overwrite
{
    NSString *itemPath = [[self getCustomPath] stringByAppendingPathComponent:[path lastPathComponent]];
    
    BOOL res = NO;
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:itemPath];
    
    if (exist && overwrite) {
        [[NSFileManager defaultManager] removeItemAtPath:itemPath error:nil];
    }
    
    if (!exist) {
        res = [[NSFileManager defaultManager] copyItemAtPath:path toPath:[[self getCustomPath] stringByAppendingPathComponent:[path lastPathComponent]] error:nil];
    }
    
    return res;
}

@end

