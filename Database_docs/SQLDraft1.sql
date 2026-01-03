-- ============================================
-- WATCH MARKETPLACE DATABASE SCHEMA (3NF)
-- PostgreSQL + Django Compatible
-- ============================================

-- ============================================
-- CORE USER MANAGEMENT
-- ============================================

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    contact_number VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('CUSTOMER', 'SELLER', 'ADMIN')),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    is_guest BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sellers (
    seller_id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    cnic VARCHAR(15) UNIQUE NOT NULL,
    verification_status VARCHAR(20) DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    verification_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE administrators (
    admin_id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    access_level VARCHAR(20) DEFAULT 'STANDARD' CHECK (access_level IN ('STANDARD', 'SUPER')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ADDRESS MANAGEMENT
-- ============================================

CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    address_type VARCHAR(20) CHECK (address_type IN ('SHIPPING', 'BILLING', 'BOTH')),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'Pakistan',
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_addresses_user_id ON addresses(user_id);

-- ============================================
-- STORE MANAGEMENT
-- ============================================

CREATE TABLE stores (
    store_id SERIAL PRIMARY KEY,
    seller_id INTEGER UNIQUE NOT NULL REFERENCES sellers(seller_id) ON DELETE CASCADE,
    store_name VARCHAR(255) UNIQUE NOT NULL,
    store_slug VARCHAR(255) UNIQUE NOT NULL,
    store_bio TEXT,
    store_logo_url VARCHAR(500),
    store_banner_url VARCHAR(500),
    store_contact VARCHAR(20),
    store_email VARCHAR(255),
    store_rating DECIMAL(3, 2) DEFAULT 0.00 CHECK (store_rating >= 0 AND store_rating <= 5),
    total_reviews INTEGER DEFAULT 0,
    total_sales DECIMAL(12, 2) DEFAULT 0.00,
    total_orders INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stores_seller_id ON stores(seller_id);
CREATE INDEX idx_stores_store_name ON stores(store_name);

-- ============================================
-- PRODUCT CATALOG
-- ============================================

CREATE TABLE product_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL,
    category_description TEXT,
    parent_category_id INTEGER REFERENCES product_categories(category_id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE brands (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(100) UNIQUE NOT NULL,
    brand_description TEXT,
    brand_logo_url VARCHAR(500),
    country_of_origin VARCHAR(100)
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    seller_id INTEGER NOT NULL REFERENCES sellers(seller_id) ON DELETE CASCADE,
    store_id INTEGER NOT NULL REFERENCES stores(store_id) ON DELETE CASCADE,
    brand_id INTEGER REFERENCES brands(brand_id) ON DELETE SET NULL,
    category_id INTEGER REFERENCES product_categories(category_id) ON DELETE SET NULL,
    
    -- Basic Information
    model_name VARCHAR(255) NOT NULL,
    reference_number VARCHAR(100),
    year_manufactured INTEGER CHECK (year_manufactured >= 1800 AND year_manufactured <= EXTRACT(YEAR FROM CURRENT_DATE) + 1),
    
    -- Condition and Authentication
    condition VARCHAR(20) NOT NULL CHECK (condition IN ('NEW', 'LIKE_NEW', 'EXCELLENT', 'GOOD', 'FAIR', 'PARTS_ONLY')),
    has_box BOOLEAN DEFAULT FALSE,
    has_papers BOOLEAN DEFAULT FALSE,
    has_warranty BOOLEAN DEFAULT FALSE,
    warranty_months INTEGER,
    pieces INTEGER,
    
    -- Pricing
    price DECIMAL(12, 2) NOT NULL CHECK (price >= 0),
    original_price DECIMAL(12, 2),
    currency VARCHAR(3) DEFAULT 'PKR',
    
    -- Status
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ACTIVE', 'SOLD', 'RESERVED', 'INACTIVE')),
    approval_status VARCHAR(20) DEFAULT 'PENDING' CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED', 'REQUIRES_CHANGES')),
    approved_by INTEGER REFERENCES administrators(admin_id),
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    
    -- Additional Details
    specifications JSONB,
    description TEXT,
    case_material VARCHAR(100),
    movement_type VARCHAR(100),
    case_diameter_mm DECIMAL(5, 2),
    water_resistance VARCHAR(50),
    
    -- Metrics
    view_count INTEGER DEFAULT 0,
    favorite_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_products_store_id ON products(store_id);
CREATE INDEX idx_products_brand_id ON products(brand_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_approval_status ON products(approval_status);
CREATE INDEX idx_products_price ON products(price);

-- ============================================
-- IMAGE MANAGEMENT
-- ============================================

CREATE TABLE images (
    image_id SERIAL PRIMARY KEY,
    image_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    alt_text VARCHAR(255),
    image_order INTEGER DEFAULT 0,
    uploaded_by INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_images (
    product_image_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    image_id INTEGER NOT NULL REFERENCES images(image_id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    UNIQUE(product_id, image_id)
);

CREATE INDEX idx_product_images_product_id ON product_images(product_id);

CREATE TABLE review_images (
    review_image_id SERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES reviews(review_id) ON DELETE CASCADE,
    image_id INTEGER NOT NULL REFERENCES images(image_id) ON DELETE CASCADE,
    display_order INTEGER DEFAULT 0
);

-- ============================================
-- ORDER MANAGEMENT
-- ============================================

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    store_id INTEGER NOT NULL REFERENCES stores(store_id) ON DELETE RESTRICT,
    
    -- Order Details
    order_number VARCHAR(50) UNIQUE NOT NULL,
    order_status VARCHAR(20) DEFAULT 'PENDING' CHECK (order_status IN 
        ('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED')),
    
    -- Pricing
    subtotal DECIMAL(12, 2) NOT NULL,
    advance_payment BOOLEAN,
    advance_amount DECIMAL(12, 2) DEFAULT 0.00,
    tax_amount DECIMAL(12, 2) DEFAULT 0.00,
    shipping_cost DECIMAL(12, 2) DEFAULT 0.00,
    total_amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'PKR',
    
    -- Addresses
    shipping_address_id INTEGER REFERENCES addresses(address_id),
    billing_address_id INTEGER REFERENCES addresses(address_id),
    
    -- Tracking
    tracking_number VARCHAR(100),
    carrier VARCHAR(100),
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    
    -- Notes
    customer_notes TEXT,
    admin_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_store_id ON orders(store_id);
CREATE INDEX idx_orders_order_status ON orders(order_status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    
    -- Item Details (snapshot at time of purchase)
    product_name VARCHAR(255) NOT NULL,
    product_price DECIMAL(12, 2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    subtotal DECIMAL(12, 2) NOT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- ============================================
-- PAYMENT MANAGEMENT
-- ============================================

CREATE TABLE payment_methods (
    payment_method_id SERIAL PRIMARY KEY,
    method_name VARCHAR(50) UNIQUE NOT NULL,
    method_description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    payment_method_id INTEGER REFERENCES payment_methods(payment_method_id),
    
    payment_tier VARCHAR(20) CHECK (payment_tier IN ('STANDARD', 'EXPRESS', 'PREMIUM')),
    payment_status VARCHAR(20) DEFAULT 'PENDING' CHECK (payment_status IN 
        ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'REFUNDED', 'CANCELLED')),
    
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'PKR',
    
    -- Transaction Details
    transaction_id VARCHAR(255) UNIQUE,
    payment_gateway VARCHAR(50),
    gateway_response JSONB,
    
    -- Timestamps
    payment_initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_completed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_payment_status ON payments(payment_status);

-- ============================================
-- REVIEWS AND RATINGS
-- ============================================

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(store_id) ON DELETE CASCADE,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE SET NULL,
    product_id INTEGER REFERENCES products(product_id) ON DELETE SET NULL,
    
    rating DECIMAL(2, 1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    description TEXT,
    
    -- Helpful votes
    helpful_count INTEGER DEFAULT 0,
    not_helpful_count INTEGER DEFAULT 0,
    
    -- Status
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(customer_id, order_id)
);

CREATE INDEX idx_reviews_store_id ON reviews(store_id);
CREATE INDEX idx_reviews_customer_id ON reviews(customer_id);
CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- ============================================
-- CHAT AND MESSAGING
-- ============================================

CREATE TABLE chat_conversations (
    conversation_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    seller_id INTEGER NOT NULL REFERENCES sellers(seller_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(product_id) ON DELETE SET NULL,
    
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED', 'ARCHIVED')),
    last_message_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(customer_id, seller_id, product_id)
);

CREATE INDEX idx_chat_conversations_customer_id ON chat_conversations(customer_id);
CREATE INDEX idx_chat_conversations_seller_id ON chat_conversations(seller_id);

CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL REFERENCES chat_conversations(conversation_id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'TEXT' CHECK (message_type IN ('TEXT', 'IMAGE', 'SYSTEM')),
    attachment_url VARCHAR(500),
    
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- ============================================
-- FAVORITES AND WATCHLIST
-- ============================================

CREATE TABLE favorites (
    favorite_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(customer_id, product_id)
);

CREATE INDEX idx_favorites_customer_id ON favorites(customer_id);
CREATE INDEX idx_favorites_product_id ON favorites(product_id);

-- ============================================
-- ADMIN ACTIVITY LOG
-- ============================================

CREATE TABLE admin_activity_log (
    log_id SERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL REFERENCES administrators(admin_id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50),
    entity_id INTEGER,
    description TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_activity_log_admin_id ON admin_activity_log(admin_id);
CREATE INDEX idx_admin_activity_log_created_at ON admin_activity_log(created_at);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    link_url VARCHAR(500),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- ============================================
-- SAMPLE DATA INSERTS
-- ============================================

-- Insert payment methods
INSERT INTO payment_methods (method_name, method_description) VALUES
    ('CASH_ON_DELIVERY', 'Cash payment upon delivery'),
    ('CREDIT_CARD', 'Credit or debit card payment'),
    ('BANK_TRANSFER', 'Direct bank transfer'),
    ('DIGITAL_WALLET', 'Digital wallet payment (JazzCash, Easypaisa)');

-- Insert product categories
INSERT INTO product_categories (category_name, category_description) VALUES
    ('Luxury Watches', 'High-end luxury timepieces'),
    ('Sports Watches', 'Watches designed for athletic activities'),
    ('Dress Watches', 'Elegant watches for formal occasions'),
    ('Smartwatches', 'Digital watches with smart features'),
    ('Vintage Watches', 'Classic and antique timepieces');