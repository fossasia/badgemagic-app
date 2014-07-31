<?php
/**
 * Setup Tweeple plugin.
 *
 * @since 0.1.0
 */
class Tweeple {

    /**
     * Only instance of object.
     * @var Tweeple
     */
    private static $instance = null;

    /**
     * Object for admin page.
     * @var Tweeple_Admin
     */
    private $admin;

    /**
     * Creates or returns an instance of this class.
     *
     * @return Tweeple A single instance of this class.
     *
     * @since 0.1.0
     */
    public static function get_instance() {
        if ( self::$instance == null ) {
            self::$instance = new self;
        }
        return self::$instance;
    }

    /**
     * Run plugin.
     *
     * @since 0.1.0
     */
    private function __construct() {

        // Library files
        if ( ! class_exists( 'tmhOAuth' ) ) {
            include_once( TWEEPLE_PLUGIN_DIR . '/lib/tmhOAuth/tmhOAuth.php' );
        }

        if ( ! class_exists( 'tmhUtilities' ) ) {
            include_once( TWEEPLE_PLUGIN_DIR . '/lib/tmhOAuth/tmhUtilities.php' );
        }

        // Plugin files
        include_once( TWEEPLE_PLUGIN_DIR . '/inc/class-tweeple-admin.php' );
        include_once( TWEEPLE_PLUGIN_DIR . '/inc/class-tweeple-feed-widget.php' );
        include_once( TWEEPLE_PLUGIN_DIR . '/inc/class-tweeple-feed.php' );
        include_once( TWEEPLE_PLUGIN_DIR . '/inc/class-tweeple-theme-blvd.php' );
        include_once( TWEEPLE_PLUGIN_DIR . '/inc/functions.php' );

        // Register text domain for localization
        $this->localize();

        // Save plugin version
        add_action( 'admin_init', array( $this, 'update_version' ) );

        // Twitter Feeds
        add_action( 'init', array( $this, 'register_post_types' ) );

        // Admin
        if ( is_admin() ) {
            $this->admin = new Tweeple_Admin();
            add_filter( 'plugin_action_links_'.TWEEPLE_PLUGIN_BASENAME, array( $this, 'settings_link' ) );
        }

        // Frontend
        add_action( 'widgets_init', array( $this, 'register_widgets' ) );
        add_shortcode( 'tweeple_feed', array( $this, 'feed_shortcode' ) );

        // Theme Blvd Integration
        Tweeple_Theme_Blvd::get_instance();

    }

    /**
     * Load plugin's textdomain "tweeple"
     *
     * @since 0.1.0
     */
    public function localize() {
        load_plugin_textdomain( 'tweeple', false, TWEEPLE_PLUGIN_DIR . '/lang' );
    }

    /**
     * Update version in the database.
     *
     * @since 0.1.0
     */
    public function update_version() {
        update_option( 'tweeple_plugin_version', TWEEPLE_PLUGIN_VERSION );
    }

    /**
     * Filter in a link to Tools > Tweeple from
     * WP Admin > Plugins > Tweeple.
     *
     * @since 0.1.0
     */
    public function settings_link( $links ) {

        $url = admin_url( $this->admin->get_parent().'?page=tweeple' );
        $link = sprintf( '<a href="%s">%s</a>', $url, __( 'Manage Feeds', 'tweeple' ) );

        array_unshift( $links, $link );

        return $links;
    }

    /**
     * Register any post types the plugin requires.
     *
     * @since 0.1.0
     */
    public function register_post_types() {

        // Twitter Feeds
        $args = apply_filters( 'tweeple_feeds_post_type_args', array(
            'labels'            => array( 'name' => 'Twitter Feeds', 'singular_name' => 'Twitter Feed' ),
            'public'            => false,
            //'show_ui'         => true,    // Can uncomment for debugging
            'query_var'         => true,
            'capability_type'   => 'post',
            'hierarchical'      => false,
            'rewrite'           => false,
            'supports'          => array( 'title', 'custom-fields' ),
            'can_export'        => true
        ));
        register_post_type( 'tweeple_feed', $args );
    }

    /**
     * Get Twitter feeds setup by user
     *
     * @since 0.1.0
     */
    public function get_feeds() {

        $feeds = array();

        // Get feeds from DB.
        $args = array(
            'post_type'     => 'tweeple_feed',
            'orderby'       => 'title',
            'order'         => 'ASC',
            'numberposts'   => -1
        );
        $posts = get_posts( $args );

        // Did we get any posts?
        if ( ! $posts ) {
            return $feeds;
        }

        // Format into simple array as Feed ID => Name
        foreach ( $posts as $post ) {
            $feeds[$post->ID] = $post->post_title;
        }

        return $feeds;
    }

    /**
     * Register Widget
     *
     * @since 0.1.0
     */
    public function register_widgets() {
        register_widget( 'tweeple_feed_widget' );
    }

    /**
     * Setup feed shortcode
     *
     * @since 0.1.0
     */
    public function feed_shortcode( $atts ) {

        // Check for missing feed id.
        if ( empty( $atts['id'] ) ) {
            return __( 'No Twitter feed ID given.', 'tweeple' );
        }

        $atts['id'] = str_replace( ' ', '', $atts['id'] );
        $ids = explode( ',', $atts['id'] );

        $feeds = array();

        foreach ( $ids as $id ) {
            $feeds[] = tweeple_get_feed( $id );
        }

        // Get Tweets
        $tweets = tweeple_get_tweets( $feeds );

        // Start output
        $output  = '<div class="tweeple tweeple-feed tweeple-feed-shortcode">';
        $output .= '<div class="tweeple-inner">';

        // Errror checking
        $error = '';

        foreach ( $feeds as $feed ) {
            if ( tweeple_error( $feed ) ) {
                $error = sprintf( '<p>%s</p>', tweeple_error( $feed ) );
            }
        }

        if ( ! $error ) {

            // We are a go! Display shortcode.
            ob_start();
            do_action( 'tweeple_display_shortcode', $tweets, $feed['options'], $feed['info'] );
            $output .= ob_get_clean();

        }

        $output .= '</div><!-- .tweeple-inner (end) -->';
        $output .= '</div><!-- .tweeple-feed-shortcode (end) -->';

        return apply_filters( 'tweeple_feed_shortcode', $output, $atts['id'], $feed );
    }
}