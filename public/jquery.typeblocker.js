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
  $.fn.typeblocker = function(defaults, opts) {
     $.typeblocker.init(defaults,opts,this);
  };

  $.typeblocker = {

    options: {
      target_width: 250,
      minimum_font_size: 10
    },

    init: function(target_width, opts, elems){
       var elems = elems || "body";
       $.extend(this.options, opts);

       this.addInlineElements(elems);
       this.increaseTypeSize();
     },

    addInlineElements: function(elems) {
      $(elems).each(function() {
        $(this).children().wrapInner("<span class='typeblocker_inner'>").children().css("white-space","nowrap");
      });
    },

    increaseTypeSize: function() {
      $(".typeblocker_inner").each(function() {
        var element = $(this);
        var current_font_size = element.css("font-size").slice(0,-2);
        var target_width = $.typeblocker.options.target_width - element.css("padding-left").slice(0,-2) - element.css("padding-right").slice(0,-2);

        while (element.width() < target_width) {
          current_font_size++;
          element.css("font-size",current_font_size);
        }
        while (element.width() > target_width) {
          current_font_size--;
          element.css("font-size",current_font_size);
        }
        // if (element.css("font-size").slice(0,-2) < target_width) {
        //   current_font_size++;
        //   element.css("font-size",current_font_size);
        // }
        if (element.css("font-size").slice(0,-2) < $.typeblocker.options.minimum_font_size) {
          element.css("font-size",$.typeblocker.options.minimum_font_size);
        }
      });
    }

  };

})(jQuery);