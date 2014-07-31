<?php
/*
Plugin Name: Tweeple
Description: Setup Twitter feeds to pull a user's public timeline, public list, favorite tweets, or a custom search term, phrase, or hashtag.
Version: 0.9.2
Author: Theme Blvd
Author URI: http://themeblvd.com
License: GPL2

    Copyright 2014  Theme Blvd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License version 2,
    as published by the Free Software Foundation.

    You may NOT assume that you can use any other version of the GPL.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    The license for this software can likely be found here:
    http://www.gnu.org/licenses/gpl-2.0.html

*/

define( 'TWEEPLE_PLUGIN_VERSION', '0.9.2' );
define( 'TWEEPLE_PLUGIN_DIR', dirname( __FILE__ ) );
define( 'TWEEPLE_PLUGIN_URI', plugins_url( '' , __FILE__ ) );
define( 'TWEEPLE_PLUGIN_BASENAME', plugin_basename( __FILE__ ) );

/**
 * Run Tweeple plugin.
 */
function tweeple_init(){

    include_once( TWEEPLE_PLUGIN_DIR . '/inc/class-tweeple.php' );

    Tweeple::get_instance();

}
add_action( 'plugins_loaded', 'tweeple_init' );

/**
 * Frontend actions and filters.
 *
 * The default hooked display functions can be found
 * in /inc/functions.php for reference.
 */
function tweeple_hooks(){

    // Remove characters and symbols that won't display in website
    add_filter( 'tweeple_tweet_text', 'tweeple_tweet_clean' );

    // Filter the text of a tweet
    add_filter( 'tweeple_tweet_text', 'tweeple_tweet_text_default' );

    // Display Widget
    add_action( 'tweeple_display_widget', 'tweeple_display_default', 10, 2 );

    // Display Shortcode
    add_action( 'tweeple_display_shortcode', 'tweeple_display_default', 10, 2 );

    // Tweet Meta
    add_action( 'tweeple_tweet_meta', 'tweeple_tweet_meta_default' );
    // add_action( 'tweeple_tweet_meta', 'tweeple_tweet_meta_fancy' );

    // "Tweet" element for Theme Blvd Layout Builder
    add_action( 'tweeple_display_tweet_element', 'tweeple_tweet_element_default', 10, 3 );

}
add_action( 'plugins_loaded', 'tweeple_hooks' );