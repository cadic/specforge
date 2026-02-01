# AGENTS.md — WordPress/PHP Example

> This is an example `AGENTS.md` for WordPress plugin development.
> Copy this file as `AGENTS.md` in your project and adapt it to your tech stack.

---

## Purpose

This file defines coding standards and patterns for AI coding assistants. When the AI makes recurring mistakes, add a rule here.

---

## Tech Stack

- **Platform:** WordPress 6.2+
- **Language:** PHP 8.0+
- **Optional:** WooCommerce 8.0+
- **Testing:** PHPUnit + WP_Mock
- **Linter:** PHPCS with WordPress Coding Standards

---

## File Naming

- Class files must follow pattern: `class-{class-name}.php` (lowercase, hyphen-separated)
- Examples: `class-email.php`, `class-database.php`, `class-gdpr.php`
- **Wrong:** `Email.php`, `Database.php`, `GDPR.php`

---

## Database Security

### Prepared Statements

Always use `$wpdb->prepare()` with placeholders. Pass table names via `%i` (WordPress 6.2+):

```php
// Correct
$wpdb->prepare( 'SELECT * FROM %i WHERE id = %d', $table_name, $id );

// Wrong — variable interpolation
$wpdb->prepare( "SELECT * FROM $table_name WHERE id = %d", $id );
```

### Caching

Use Object Cache for direct database queries:

```php
$cache_key = 'rsvp_event_' . $event_id;
$result    = wp_cache_get( $cache_key, 'simple-rsvp' );

if ( false === $result ) {
    $result = $wpdb->get_results( ... );
    wp_cache_set( $cache_key, $result, 'simple-rsvp', HOUR_IN_SECONDS );
}
```

---

## Form Security

Always verify nonce when processing form data:

```php
if ( ! isset( $_POST['_wpnonce'] ) || ! wp_verify_nonce( $_POST['_wpnonce'], 'action_name' ) ) {
    wp_die( 'Security check failed' );
}
```

---

## Input/Output Safety

### Escaping Output

Always escape output based on context:

```php
esc_html( $text );      // For HTML content
esc_attr( $attribute ); // For HTML attributes
esc_url( $url );        // For URLs
esc_js( $string );      // For inline JavaScript
wp_kses_post( $html );  // For post content with allowed HTML
```

### Sanitizing Input

Always sanitize input based on expected type:

```php
sanitize_text_field( $_POST['name'] );
absint( $_POST['id'] );
sanitize_email( $_POST['email'] );
wp_kses_post( $_POST['content'] );
```

---

## Formatting

### Assignment Alignment

Align `=` signs in assignment blocks:

```php
$short     = 1;
$longer    = 2;
$very_long = 3;
```

### Parentheses Spacing

Add spaces inside parentheses for functions and conditions:

```php
// Correct
if ( $condition ) {
    my_function( $arg1, $arg2 );
}

// Wrong
if ($condition) {
    my_function($arg1, $arg2);
}
```

### Multi-line Function Calls

Place each argument on a separate line with closing parenthesis on its own line:

```php
$result = some_function(
    $argument_one,
    $argument_two,
    $argument_three
);
```

---

## WordPress Storage APIs

Use the appropriate storage mechanism:

| Storage Type | Use Case | Functions |
|--------------|----------|-----------|
| Options API | Plugin settings, global config | `get_option()`, `update_option()` |
| Post Meta | Data attached to posts/pages | `get_post_meta()`, `update_post_meta()` |
| User Meta | Data attached to users | `get_user_meta()`, `update_user_meta()` |
| Transients | Cached data with expiration | `get_transient()`, `set_transient()` |
| Custom Tables | Large datasets, complex queries | `$wpdb->get_results()`, `dbDelta()` |

---

## Hooks and Filters

### Registering Actions

```php
add_action( 'init', array( $this, 'register_post_types' ) );
add_action( 'wp_enqueue_scripts', array( $this, 'enqueue_assets' ) );
```

### Registering Filters

```php
add_filter( 'the_content', array( $this, 'modify_content' ) );
add_filter( 'query_vars', array( $this, 'add_query_vars' ) );
```

### Creating Custom Hooks

```php
// Allow other plugins to modify data
$data = apply_filters( 'my_plugin_data', $data, $context );

// Allow other plugins to act on events
do_action( 'my_plugin_after_save', $post_id, $data );
```

---

## WooCommerce Specifics

### HPOS Compatibility

Always use CRUD methods for order data, never direct database access:

```php
// Correct
$order->get_billing_email();
$order->get_meta( '_custom_field' );

// Wrong
get_post_meta( $order_id, '_billing_email', true );
```

### Declaring HPOS Compatibility

```php
add_action( 'before_woocommerce_init', function() {
    if ( class_exists( \Automattic\WooCommerce\Utilities\FeaturesUtil::class ) ) {
        \Automattic\WooCommerce\Utilities\FeaturesUtil::declare_compatibility(
            'custom_order_tables',
            __FILE__,
            true
        );
    }
} );
```

---

## File Operations

Use `WP_Filesystem` instead of direct PHP functions:

```php
global $wp_filesystem;
WP_Filesystem();

$wp_filesystem->put_contents( $file, $content );

// Instead of: fwrite(), fclose(), file_put_contents()
```

---

## Debugging

Never leave `error_log()` in production code. Use conditional logging:

```php
if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
    error_log( $message );
}
```

---

## Dependency Management

Never edit `composer.json` or `package.json` manually to add dependencies. Use CLI commands instead:

```bash
# Composer
composer require vendor/package
composer require --dev vendor/package

# NPM
npm install package-name
npm install --save-dev package-name
```

This ensures proper version resolution, lock file updates, and immediate installation.

---

## Testing

### PHPUnit + WP_Mock

```php
use WP_Mock;
use PHPUnit\Framework\TestCase;

class MyTest extends TestCase {
    public function setUp(): void {
        WP_Mock::setUp();
    }

    public function tearDown(): void {
        WP_Mock::tearDown();
    }

    public function test_something(): void {
        WP_Mock::userFunction( 'get_option' )
            ->with( 'my_option' )
            ->andReturn( 'value' );

        // ... test code
    }
}
```

### Running Tests

```bash
composer test
# or
./vendor/bin/phpunit
```

---

## Auto-fixing

Run `composer phpcbf` to automatically fix style violations (alignment, spacing).

---

## REST API

### Registering Endpoints

```php
add_action( 'rest_api_init', function() {
    register_rest_route( 'my-plugin/v1', '/items', array(
        'methods'             => 'GET',
        'callback'            => 'get_items_callback',
        'permission_callback' => function() {
            return current_user_can( 'read' );
        },
    ) );
} );
```

### Response Format

```php
return new WP_REST_Response( $data, 200 );
return new WP_Error( 'error_code', 'Error message', array( 'status' => 400 ) );
```
