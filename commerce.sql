-- ecommerce_schema.sql
-- Complete MySQL schema for a realistic e-commerce store
-- Includes CREATE DATABASE, tables, constraints, indexes and human-friendly comments

DROP DATABASE IF EXISTS `ecommerce_db`;
CREATE DATABASE `ecommerce_db` CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_general_ci';
USE `ecommerce_db`;

-- -----------------------------------------------------------------------------
-- SETTINGS (storage engine, time zone awareness)
-- -----------------------------------------------------------------------------
SET @@SESSION.sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------------------------------
-- Table: users
-- Stores customers and admin accounts. email is unique. password is hashed.
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    role ENUM('customer','merchant','admin') NOT NULL DEFAULT 'customer',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: addresses
-- One user can have many addresses (billing/shipping). Address can be reused.
-- -----------------------------------------------------------------------------
CREATE TABLE addresses (
    address_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NULL,
    label VARCHAR(50) DEFAULT 'home', -- e.g., home, work
    recipient_name VARCHAR(200) NULL,
    line1 VARCHAR(255) NOT NULL,
    line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(30),
    country VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (address_id),
    CONSTRAINT fk_addresses_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: categories
-- Product grouping. Hierarchical via parent_id.
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
    category_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    slug VARCHAR(200) NOT NULL,
    parent_id INT UNSIGNED DEFAULT NULL,
    description TEXT,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_categories_slug (slug),
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(category_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: suppliers
-- Optional vendors or suppliers for inventory management
-- -----------------------------------------------------------------------------
CREATE TABLE suppliers (
    supplier_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (supplier_id),
    UNIQUE KEY uq_suppliers_name (name)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: products
-- Main product catalog. SKU is unique.
-- -----------------------------------------------------------------------------
CREATE TABLE products (
    product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    sku VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    short_description VARCHAR(500),
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    retail_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    weight_kg DECIMAL(8,3),
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id),
    UNIQUE KEY uq_products_sku (sku),
    INDEX idx_products_name (name)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: product_images
-- Multiple images per product. Sort order kept by position.
-- -----------------------------------------------------------------------------
CREATE TABLE product_images (
    image_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id BIGINT UNSIGNED NOT NULL,
    url VARCHAR(1024) NOT NULL,
    alt_text VARCHAR(255),
    position INT UNSIGNED NOT NULL DEFAULT 0,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (image_id),
    INDEX idx_product_images_product (product_id),
    CONSTRAINT fk_product_images_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: product_categories (many-to-many)
-- Connects products to categories
-- -----------------------------------------------------------------------------
CREATE TABLE product_categories (
    product_id BIGINT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_pc_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pc_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: inventory
-- Tracks stock per product optionally by supplier/batch
-- -----------------------------------------------------------------------------
CREATE TABLE inventory (
    inventory_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id BIGINT UNSIGNED NOT NULL,
    supplier_id INT UNSIGNED,
    quantity INT NOT NULL DEFAULT 0,
    reserved INT NOT NULL DEFAULT 0, -- reserved for carts/orders
    location VARCHAR(255),
    last_restocked TIMESTAMP NULL,
    PRIMARY KEY (inventory_id),
    INDEX idx_inventory_product (product_id),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_inventory_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: coupons
-- Discount codes
-- -----------------------------------------------------------------------------
CREATE TABLE coupons (
    coupon_code VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    discount_type ENUM('percent','fixed') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    usage_limit INT UNSIGNED DEFAULT NULL,
    expires_at DATETIME DEFAULT NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (coupon_code)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: orders
-- Each order belongs to a user (nullable for guest checkouts) and has a billing + shipping address
-- -----------------------------------------------------------------------------
CREATE TABLE orders (
    order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NULL,
    order_number VARCHAR(50) NOT NULL, -- e.g., store-specific sequential or prefixed ID
    status ENUM('pending','paid','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
    total_amount DECIMAL(12,2) NOT NULL,
    shipping_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    coupon_code VARCHAR(50) DEFAULT NULL,
    billing_address_id BIGINT UNSIGNED DEFAULT NULL,
    shipping_address_id BIGINT UNSIGNED DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id),
    UNIQUE KEY uq_orders_number (order_number),
    INDEX idx_orders_user (user_id),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_code) REFERENCES coupons(coupon_code) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_orders_billing_address FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_orders_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: order_items
-- Junction table of orders and products with price-at-time and quantity
-- Many-to-many between orders and products
-- -----------------------------------------------------------------------------
CREATE TABLE order_items (
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    sku VARCHAR(100) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 1,
    total_price DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    INDEX idx_order_items_order (order_id),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: payments
-- One payment record per order (could be extended to multiple payments)
-- -----------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id BIGINT UNSIGNED NOT NULL,
    payment_method ENUM('card','mpesa','paypal','bank_transfer','cash_on_delivery') NOT NULL,
    provider_transaction_id VARCHAR(255),
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    status ENUM('initiated','completed','failed','refunded') NOT NULL DEFAULT 'initiated',
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (payment_id),
    UNIQUE KEY uq_payments_provider_tx (provider_transaction_id),
    INDEX idx_payments_order (order_id),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: reviews
-- Customer reviews for products
-- -----------------------------------------------------------------------------
CREATE TABLE reviews (
    review_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title VARCHAR(255),
    body TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id),
    UNIQUE KEY uq_reviews_user_product (product_id, user_id),
    CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: carts
-- Lightweight carts tied to users or sessions (guest carts would use session_id)
-- -----------------------------------------------------------------------------
CREATE TABLE carts (
    cart_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED DEFAULT NULL,
    session_id VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (cart_id),
    INDEX idx_carts_user (user_id),
    CONSTRAINT fk_carts_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: cart_items
-- Items reserved in a user's cart. Quantity can be changed.
-- -----------------------------------------------------------------------------
CREATE TABLE cart_items (
    cart_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 1,
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (cart_id, product_id),
    CONSTRAINT fk_cart_items_cart FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: wishlists
-- Simple wishlist per user
-- -----------------------------------------------------------------------------
CREATE TABLE wishlists (
    wishlist_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(150) DEFAULT 'My Wishlist',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (wishlist_id),
    INDEX idx_wishlists_user (user_id),
    CONSTRAINT fk_wishlists_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE wishlist_items (
    wishlist_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (wishlist_id, product_id),
    CONSTRAINT fk_wishlist_items_wishlist FOREIGN KEY (wishlist_id) REFERENCES wishlists(wishlist_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_wishlist_items_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Table: product_attributes
-- Optional flexible attributes (size, color) - key/value per product
-- -----------------------------------------------------------------------------
CREATE TABLE product_attributes (
    attr_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id BIGINT UNSIGNED NOT NULL,
    attr_key VARCHAR(100) NOT NULL,
    attr_value VARCHAR(255) NOT NULL,
    PRIMARY KEY (attr_id),
    INDEX idx_prod_attr_product (product_id),
    CONSTRAINT fk_prod_attr_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Helpful views (optional) - example: order totals per user
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_user_order_totals AS
SELECT u.user_id, u.email, COUNT(o.order_id) AS orders_count, COALESCE(SUM(o.total_amount),0) AS total_spent
FROM users u
LEFT JOIN orders o ON o.user_id = u.user_id
GROUP BY u.user_id, u.email;

-- -----------------------------------------------------------------------------
-- Example stored procedure (optional): create a sequential order number
-- Note: in production you might use a different strategy (dedicated counter table)
-- -----------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_generate_order_number(OUT out_order_number VARCHAR(50))
BEGIN
  -- Simple: prefix + unix timestamp + random 3 digits
  SET out_order_number = CONCAT('ORD-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '-', LPAD(FLOOR(RAND()*999),3,'0'));
END$$
DELIMITER ;

-- -----------------------------------------------------------------------------
-- End of schema
-- You can extend with audit tables, logs, analytics tables, or multi-warehouse inventory.
-- -----------------------------------------------------------------------------
