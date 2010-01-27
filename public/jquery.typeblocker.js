/*  
 *  TypeBlocker
 * 
 *  Developed by Phil Oye
 *  Copyright (c) 2010 Phil Oye, http://philoye.com/
 *
 *  Licensed under the MIT license:
 *  http://www.opensource.org/licenses/mit-license.php
 *
 */

(function($) {
  $.fn.typeblocker = function(target_width, opts) {
     $.typeblocker.init(target_width,opts,this);
  };

  $.typeblocker = {

    options: {
      minimum_font_size: 10,
      ignore_child_selector: ""
    },

    init: function(target_width, opts, elems){
       var elems = elems || "body";
       $.extend(this.options, opts);

       this.addInlineElements(elems);
       this.increaseTypeSize(target_width);
     },

    addInlineElements: function(elems) {
      var ignore_selector = ":not(" + $.typeblocker.options.ignore_child_selector + ")";
      
      $(elems).each(function() {
        $(this).children(ignore_selector).wrapInner("<span class='typeblocker_inner'>").children().css("white-space","nowrap");
      });
    },

    increaseTypeSize: function(target_width) {
      $(".typeblocker_inner").each(function() {
        var element = $(this);
        var current_font_size = element.css("font-size").slice(0,-2);
        var new_width = target_width - element.css("padding-left").slice(0,-2) - element.css("padding-right").slice(0,-2);

        while (element.width() < new_width) {
          current_font_size++;
          element.css("font-size",current_font_size);
        }
        while (element.width() > new_width) {
          current_font_size--;
          element.css("font-size",current_font_size);
        }
        if (element.css("font-size").slice(0,-2) < $.typeblocker.options.minimum_font_size) {
          element.css("font-size",$.typeblocker.options.minimum_font_size);
        }
      });
    }

  };

})(jQuery);