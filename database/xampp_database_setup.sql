-- XAMPP MySQL Setup for Bangladesh Rental Management System
-- Import this file in phpMyAdmin

-- Make sure we're using the right database
USE rasa_db;

-- Users table (owners and tenants)
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    phone VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    user_type ENUM('owner', 'tenant', 'both') NOT NULL,
    profile_image VARCHAR(255),
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_ratings INT DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Add indexes
ALTER TABLE users ADD INDEX idx_phone (phone);
ALTER TABLE users ADD INDEX idx_email (email);
ALTER TABLE users ADD INDEX idx_user_type (user_type);

-- Properties table (simplified for XAMPP)
CREATE TABLE properties (
    id INT PRIMARY KEY AUTO_INCREMENT,
    owner_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Location data (using separate lat/lng fields for XAMPP compatibility)
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address TEXT NOT NULL,
    area_name VARCHAR(100) NOT NULL,
    neighborhood VARCHAR(100),
    
    -- Property details
    property_type ENUM('single_room', 'studio', 'apartment', 'flat', 'commercial') NOT NULL,
    occupancy_type ENUM('bachelor', 'family', 'female_only', 'male_only', 'mixed') NOT NULL,
    
    -- Pricing
    rent_amount DECIMAL(10,2) NOT NULL,
    security_deposit DECIMAL(10,2),
    advance_months INT DEFAULT 2,
    utility_included BOOLEAN DEFAULT FALSE,
    
    -- Property features
    furnished BOOLEAN DEFAULT FALSE,
    total_rooms INT DEFAULT 1,
    bathrooms INT DEFAULT 1,
    balcony BOOLEAN DEFAULT FALSE,
    kitchen_access BOOLEAN DEFAULT FALSE,
    
    -- Amenities (stored as JSON)
    amenities JSON,
    
    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    available_from DATE,
    
    -- Images
    images JSON,
    
    -- Metadata
    views INT DEFAULT 0,
    featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Add indexes and foreign keys
ALTER TABLE properties ADD INDEX idx_area (area_name);
ALTER TABLE properties ADD INDEX idx_rent (rent_amount);
ALTER TABLE properties ADD INDEX idx_type (property_type);
ALTER TABLE properties ADD INDEX idx_available (is_available);
ALTER TABLE properties ADD INDEX idx_owner (owner_id);
ALTER TABLE properties ADD FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;

-- Nearby places table
CREATE TABLE nearby_places (
    id INT PRIMARY KEY AUTO_INCREMENT,
    property_id INT NOT NULL,
    place_name VARCHAR(100) NOT NULL,
    place_type ENUM('restaurant', 'hospital', 'school', 'university', 'market', 'mosque', 'transport') NOT NULL,
    distance_meters INT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE
);

ALTER TABLE nearby_places ADD INDEX idx_property (property_id);
ALTER TABLE nearby_places ADD INDEX idx_type (place_type);

-- Transportation options
CREATE TABLE transportation (
    id INT PRIMARY KEY AUTO_INCREMENT,
    property_id INT NOT NULL,
    transport_type ENUM('bus', 'metro', 'rickshaw', 'cng', 'uber', 'pathao') NOT NULL,
    details VARCHAR(255),
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE
);

ALTER TABLE transportation ADD INDEX idx_property (property_id);

-- Search analytics for the chatbot
CREATE TABLE search_analytics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    search_location VARCHAR(100),
    search_budget DECIMAL(10,2),
    search_preferences JSON,
    results_count INT,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE search_analytics ADD INDEX idx_location (search_location);
ALTER TABLE search_analytics ADD INDEX idx_budget (search_budget);
ALTER TABLE search_analytics ADD INDEX idx_created (created_at);

-- Chatbot conversation logs
CREATE TABLE bot_conversations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    session_id VARCHAR(100),
    user_message TEXT NOT NULL,
    bot_response TEXT NOT NULL,
    intent VARCHAR(50),
    confidence DECIMAL(4,3),
    entities JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE bot_conversations ADD INDEX idx_user (user_id);
ALTER TABLE bot_conversations ADD INDEX idx_session (session_id);
ALTER TABLE bot_conversations ADD INDEX idx_intent (intent);

-- Insert demo users
INSERT INTO users (phone, email, full_name, user_type, rating, total_ratings, is_verified) VALUES
('01711123456', 'rahman@example.com', 'Md. Abdul Rahman', 'owner', 4.5, 25, TRUE),
('01711234567', 'karim@example.com', 'Abdul Karim Sheikh', 'owner', 4.2, 18, TRUE),
('01711345678', 'fatima@example.com', 'Fatima Khatun', 'owner', 4.8, 32, TRUE),
('01711456789', 'hassan@example.com', 'Md. Hassan Ali', 'owner', 4.1, 15, TRUE),
('01711567890', 'nasir@example.com', 'Nasir Uddin', 'owner', 4.6, 28, TRUE);

-- Insert demo properties with real Bangladesh coordinates
-- Property 1: Dhanmondi near TSC
INSERT INTO properties (
    owner_id, title, description, latitude, longitude, address, area_name, neighborhood,
    property_type, occupancy_type, rent_amount, security_deposit, furnished,
    total_rooms, bathrooms, amenities, is_available, available_from
) VALUES (
    1, 'Cozy Single Room near TSC Dhaka University',
    'Well-furnished single room perfect for students and young professionals. Walking distance to TSC, Ramna Park, and New Market.',
    23.7297, 90.3958, 'House 15/A, Road 7, Dhanmondi, Dhaka-1205',
    'Dhaka', 'Dhanmondi',
    'single_room', 'bachelor',
    15000.00, 30000.00, TRUE,
    1, 1,
    JSON_ARRAY('WiFi', 'AC', 'Study Table', 'Attached Bathroom', 'Generator', 'Security'),
    TRUE, '2025-01-15'
);

-- Property 2: Gulshan luxury
INSERT INTO properties (
    owner_id, title, description, latitude, longitude, address, area_name, neighborhood,
    property_type, occupancy_type, rent_amount, security_deposit, furnished,
    total_rooms, bathrooms, amenities, is_available, available_from
) VALUES (
    2, 'Luxury Studio Apartment in Gulshan 2',
    'Premium studio apartment in the heart of Gulshan with modern amenities and excellent security.',
    23.7806, 90.4125, 'Road 32, House 8/B, Gulshan 2, Dhaka-1212',
    'Dhaka', 'Gulshan',
    'studio', 'mixed',
    25000.00, 50000.00, TRUE,
    1, 1,
    JSON_ARRAY('WiFi', 'AC', 'Kitchen', 'Parking', 'Security', 'Lift', 'Generator', 'Gym Access'),
    TRUE, '2025-02-01'
);

-- Property 3: Uttara affordable
INSERT INTO properties (
    owner_id, title, description, latitude, longitude, address, area_name, neighborhood,
    property_type, occupancy_type, rent_amount, security_deposit, furnished,
    total_rooms, bathrooms, amenities, is_available, available_from
) VALUES (
    3, 'Affordable Single Room in Uttara Sector 7',
    'Budget-friendly single room in planned Uttara area with metro rail connectivity.',
    23.8759, 90.3795, 'House 25, Road 12, Sector 7, Uttara, Dhaka-1230',
    'Dhaka', 'Uttara',
    'single_room', 'male_only',
    12000.00, 24000.00, FALSE,
    1, 1,
    JSON_ARRAY('WiFi', 'Fan', 'Study Area', 'Common Kitchen', 'Rooftop Access'),
    TRUE, '2025-01-20'
);

-- Property 4: Banani family
INSERT INTO properties (
    owner_id, title, description, latitude, longitude, address, area_name, neighborhood,
    property_type, occupancy_type, rent_amount, security_deposit, furnished,
    total_rooms, bathrooms, amenities, is_available, available_from
) VALUES (
    4, 'Spacious 2-Bedroom Apartment in Banani',
    'Perfect for small families or professionals sharing. Located in diplomatic zone.',
    23.7937, 90.4040, 'Road 11, House 45, Banani, Dhaka-1213',
    'Dhaka', 'Banani',
    'apartment', 'family',
    35000.00, 70000.00, TRUE,
    2, 2,
    JSON_ARRAY('WiFi', 'AC', 'Kitchen', 'Parking', 'Security', 'Lift', 'Balcony', 'Generator'),
    TRUE, '2025-02-15'
);

-- Property 5: Mohammadpur budget
INSERT INTO properties (
    owner_id, title, description, latitude, longitude, address, area_name, neighborhood,
    property_type, occupancy_type, rent_amount, security_deposit, furnished,
    total_rooms, bathrooms, amenities, is_available, available_from
) VALUES (
    5, 'Simple Single Room in Mohammadpur',
    'Basic but clean single room in residential Mohammadpur area.',
    23.7639, 90.3611, 'Block C, House 78, Mohammadpur, Dhaka-1207',
    'Dhaka', 'Mohammadpur',
    'single_room', 'bachelor',
    8000.00, 16000.00, FALSE,
    1, 1,
    JSON_ARRAY('WiFi', 'Fan', 'Common Bathroom', 'Kitchen Access'),
    TRUE, '2025-01-10'
);

-- Property 6: Chittagong
INSERT INTO properties (
    owner_id, title, description, latitude, longitude, address, area_name, neighborhood,
    property_type, occupancy_type, rent_amount, security_deposit, furnished,
    total_rooms, bathrooms, amenities, is_available, available_from
) VALUES (
    1, 'Sea-View Room in Chittagong Agrabad',
    'Beautiful room with partial sea view in commercial Agrabad area.',
    22.3475, 91.8311, 'Building 12, Agrabad Commercial Area, Chittagong-4100',
    'Chittagong', 'Agrabad',
    'single_room', 'mixed',
    18000.00, 36000.00, TRUE,
    1, 1,
    JSON_ARRAY('WiFi', 'AC', 'Sea View', 'Generator', 'Security'),
    TRUE, '2025-02-01'
);

-- Insert nearby places
INSERT INTO nearby_places (property_id, place_name, place_type, distance_meters) VALUES
-- For Property 1 (Dhanmondi)
(1, 'TSC (Teacher Student Center)', 'university', 300),
(1, 'Dhaka University', 'university', 500),
(1, 'Ramna Park', 'transport', 400),
(1, 'New Market', 'market', 800),
(1, 'Dhaka Medical College Hospital', 'hospital', 1200),

-- For Property 2 (Gulshan)
(2, 'American Embassy', 'transport', 200),
(2, 'Gulshan Market', 'market', 300),
(2, 'United Hospital', 'hospital', 600),
(2, 'Gulshan Ladies Club', 'restaurant', 400),
(2, 'Gulshan 2 Circle', 'transport', 150),

-- For Property 3 (Uttara)
(3, 'Uttara University', 'university', 800),
(3, 'Rajlakshmi Market', 'market', 500),
(3, 'Metro Rail Station', 'transport', 400),
(3, 'Crescent Hospital', 'hospital', 1000),

-- For Property 4 (Banani)
(4, 'Banani Graveyard', 'transport', 300),
(4, 'Banani Club', 'restaurant', 200),
(4, 'British High Commission', 'transport', 500),
(4, 'Square Hospital', 'hospital', 800),

-- For Property 5 (Mohammadpur)
(5, 'Mohammadpur Bus Stand', 'transport', 200),
(5, 'Shyamoli Cinema Hall', 'transport', 600),
(5, 'Local Market', 'market', 300),
(5, 'Mohammadpur Mosque', 'mosque', 150);

-- Insert transportation options
INSERT INTO transportation (property_id, transport_type, details) VALUES
-- For Property 1 (Dhanmondi)
(1, 'bus', '2 min walk to bus stop, direct buses to all major areas'),
(1, 'rickshaw', 'Available 24/7, easy access to TSC and Ramna'),
(1, 'cng', '5 min walk to main road for CNG'),
(1, 'uber', 'Regular Uber/Pathao availability'),

-- For Property 2 (Gulshan)
(2, 'bus', 'Circle bus route, connects to Motijheel and Dhanmondi'),
(2, 'cng', 'CNG stand 2 min walk away'),
(2, 'uber', 'Premium location with excellent ride availability'),

-- For Property 3 (Uttara)
(3, 'metro', '6 min walk to Uttara North Metro Station'),
(3, 'bus', 'Direct buses to Farmgate, Motijheel, Old Dhaka'),
(3, 'rickshaw', 'Local rickshaw available for short distances'),

-- For Property 4 (Banani)
(4, 'bus', 'Multiple bus routes available from nearby roads'),
(4, 'cng', 'Easy CNG access from main road'),
(4, 'uber', 'Excellent ride-sharing service availability'),

-- For Property 5 (Mohammadpur)
(5, 'bus', 'Mohammadpur bus stand 3 min walk'),
(5, 'rickshaw', 'Local rickshaw service available'),
(5, 'cng', 'CNG available from main road');

-- Verify the setup
SELECT 'Database setup completed successfully!' as status;
SELECT COUNT(*) as total_properties FROM properties;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_nearby_places FROM nearby_places;
SELECT COUNT(*) as total_transportation FROM transportation;
