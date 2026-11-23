-- Run after azure_sql_schema.sql. Matches the sample catalog in src/setup_db.py.
-- Requires empty products, reviews, and orders tables; does not insert orders.
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @row_count BIGINT;
    SELECT @row_count = COUNT_BIG(*) FROM dbo.products WITH (TABLOCKX, HOLDLOCK);
    IF @row_count > 0
        THROW 50001, 'Seed requires empty products, reviews, and orders tables; no data was changed.', 1;
    SELECT @row_count = COUNT_BIG(*) FROM dbo.reviews WITH (TABLOCKX, HOLDLOCK);
    IF @row_count > 0
        THROW 50001, 'Seed requires empty products, reviews, and orders tables; no data was changed.', 1;
    SELECT @row_count = COUNT_BIG(*) FROM dbo.orders WITH (TABLOCKX, HOLDLOCK);
    IF @row_count > 0
        THROW 50001, 'Seed requires empty products, reviews, and orders tables; no data was changed.', 1;

    INSERT INTO dbo.products (id, name, category, price, description, is_organic)
    VALUES
        (1, N'Organic Raw Honey', N'honey', 14.99, N'Pure organic raw honey, unfiltered and cold-pressed', 1),
        (2, N'Wildflower Honey', N'honey', 12.99, N'Natural wildflower honey from local beekeepers', 0),
        (3, N'Organic Manuka Honey', N'honey', 29.99, N'Premium organic Manuka honey from New Zealand', 1),
        (4, N'Clover Honey', N'honey', 8.99, N'Classic clover honey, smooth and sweet', 0),
        (5, N'Organic Buckwheat Honey', N'honey', 18.99, N'Dark and robust organic buckwheat honey, antioxidant-rich', 1),
        (6, N'Orange Blossom Honey', N'honey', 15.99, N'Light and floral orange blossom honey', 0),
        (7, N'Organic Acacia Honey', N'honey', 17.99, N'Light and mild organic acacia honey, low glycemic index', 1),
        (8, N'Creamed Honey', N'honey', 11.99, N'Smooth creamed honey with spreadable texture', 0),
        (9, N'Organic Extra Virgin Olive Oil', N'oil', 16.99, N'Cold-pressed organic EVOO from Mediterranean olives', 1),
        (10, N'Coconut Oil', N'oil', 12.49, N'Refined coconut oil, great for high-heat cooking', 0),
        (11, N'Organic Flaxseed Oil', N'oil', 14.99, N'Cold-pressed organic flaxseed oil, rich in omega-3', 1),
        (12, N'Avocado Oil', N'oil', 18.99, N'Cold-pressed avocado oil, high smoke point', 0),
        (13, N'Organic Almonds', N'nuts', 11.99, N'Raw organic almonds, unsalted, non-GMO certified', 1),
        (14, N'Roasted Cashews', N'nuts', 9.99, N'Lightly salted dry-roasted cashews', 0),
        (15, N'Organic Chia Seeds', N'seeds', 8.49, N'Organic black chia seeds, high in fiber and omega-3', 1),
        (16, N'Mixed Nuts', N'nuts', 13.99, N'Premium mix of walnuts, pecans, almonds and Brazil nuts', 0),
        (17, N'Organic Quinoa', N'grains', 10.99, N'Organic white quinoa, complete protein, gluten-free', 1),
        (18, N'Rolled Oats', N'grains', 5.49, N'Whole grain rolled oats, great for porridge and baking', 0),
        (19, N'Organic Brown Rice', N'grains', 7.99, N'Long-grain organic brown rice, naturally gluten-free', 1),
        (20, N'Steel-Cut Oats', N'grains', 6.99, N'Traditional steel-cut oats, low GI, hearty texture', 0),
        (21, N'Organic Green Tea', N'tea', 12.99, N'Japanese organic sencha green tea, 50 bags', 1),
        (22, N'Chamomile Tea', N'tea', 8.99, N'Dried chamomile flowers, caffeine-free, soothing', 0),
        (23, N'Organic Ethiopian Coffee', N'coffee', 16.99, N'Single-origin organic Arabica, medium roast whole bean', 1),
        (24, N'Dark Roast Espresso Blend', N'coffee', 14.49, N'Bold dark roast espresso blend, ground', 0),
        (25, N'Organic Granola', N'snacks', 9.99, N'Organic oat granola with honey, almonds and dried cranberries', 1),
        (26, N'Rice Cakes', N'snacks', 4.49, N'Lightly salted brown rice cakes, low calorie', 0),
        (27, N'Organic Dried Mango', N'snacks', 7.99, N'Unsweetened organic dried mango slices, no preservatives', 1),
        (28, N'Trail Mix', N'snacks', 8.49, N'Classic trail mix with raisins, M&Ms, peanuts and sunflower seeds', 0),
        (29, N'Organic Almond Milk', N'dairy-alt', 4.99, N'Unsweetened organic almond milk, fortified with calcium', 1),
        (30, N'Oat Milk', N'dairy-alt', 4.49, N'Barista-style oat milk, great for coffee', 0),
        (31, N'Organic Coconut Milk', N'dairy-alt', 3.99, N'Full-fat organic coconut milk, great for curries', 1),
        (32, N'Soy Milk', N'dairy-alt', 3.49, N'Unsweetened soy milk, high protein', 0);

    INSERT INTO dbo.reviews (product_id, rating, reviewer_name, review_text)
    VALUES
        (1, 5.0, N'Alice', N'Amazing honey! Best I''ve ever tried.'),
        (1, 4.0, N'Bob', N'Good quality, will buy again.'),
        (1, 5.0, N'Carol', N'Excellent raw flavor, very pure.'),
        (1, 4.5, N'Dave', N'Very good, love that it''s unfiltered.'),
        (2, 4.0, N'Eve', N'Decent honey for the price.'),
        (2, 3.5, N'Frank', N'Average, nothing special.'),
        (2, 4.0, N'Grace', N'Good everyday honey.'),
        (3, 5.0, N'Henry', N'Worth every penny, incredible quality.'),
        (3, 4.5, N'Iris', N'Excellent antibacterial properties.'),
        (3, 5.0, N'Jack', N'Best honey I have ever tasted.'),
        (4, 3.5, N'Kate', N'Okay for cooking, nothing fancy.'),
        (4, 3.5, N'Leo', N'Nothing special, pretty generic.'),
        (4, 3.5, N'Mia', N'Average clover honey.'),
        (5, 5.0, N'Noah', N'Rich bold flavor, great in tea.'),
        (5, 4.0, N'Olivia', N'Good strong honey, unique taste.'),
        (5, 5.0, N'Paul', N'Love the dark color and depth.'),
        (5, 4.5, N'Quinn', N'Great organic option at this price.'),
        (6, 4.0, N'Rachel', N'Nice floral flavor.'),
        (6, 4.5, N'Sam', N'Lovely and delicate.'),
        (6, 4.0, N'Tina', N'Good for baking.'),
        (7, 5.0, N'Uma', N'Perfect mild flavor, love it!'),
        (7, 4.5, N'Victor', N'Excellent light honey.'),
        (7, 4.5, N'Wendy', N'Great product, very pure taste.'),
        (7, 5.0, N'Xavier', N'Wonderful, highly recommend.'),
        (8, 4.0, N'Yvonne', N'Nice spreadable texture.'),
        (8, 4.0, N'Zack', N'Good on toast.'),
        (8, 4.0, N'Amy', N'Decent creamed honey.'),
        (9, 5.0, N'Brian', N'Best olive oil I''ve used, very fresh.'),
        (9, 4.5, N'Clara', N'Great flavor, organic certified.'),
        (9, 4.5, N'Derek', N'Excellent quality, love it.'),
        (10, 4.0, N'Elena', N'Good for frying, neutral taste.'),
        (10, 3.5, N'Felix', N'Does the job, nothing exciting.'),
        (10, 3.5, N'Gina', N'Decent but slightly greasy.'),
        (11, 5.0, N'Harry', N'Great for smoothies, very fresh.'),
        (11, 4.0, N'Isla', N'Good omega-3 source, mild flavor.'),
        (11, 4.5, N'James', N'Love this for salad dressings.'),
        (12, 4.5, N'Karen', N'Excellent smoke point, tastes great.'),
        (12, 4.0, N'Liam', N'Good all-purpose oil.'),
        (12, 4.5, N'Maya', N'Great for cooking and salads.'),
        (13, 5.0, N'Nate', N'Crunchy and fresh, great snack.'),
        (13, 4.5, N'Olivia', N'Love that they''re organic and raw.'),
        (13, 4.5, N'Peter', N'Perfect size, very fresh.'),
        (13, 5.0, N'Rita', N'Best almonds I''ve bought online.'),
        (14, 4.0, N'Steve', N'Good cashews, nice crunch.'),
        (14, 4.0, N'Tara', N'Tasty but slightly over-salted.'),
        (14, 4.0, N'Ursula', N'Good value for the quantity.'),
        (15, 4.5, N'Vince', N'Easy to add to smoothies, love it.'),
        (15, 4.5, N'Wanda', N'Great fiber source, very fresh.'),
        (15, 4.5, N'Xena', N'Good quality organic chia seeds.'),
        (16, 4.0, N'Yuri', N'Good mix, well-balanced variety.'),
        (16, 3.5, N'Zara', N'A bit too many peanuts for my taste.'),
        (16, 4.0, N'Alex', N'Nice mix for snacking.'),
        (16, 3.5, N'Blake', N'Would prefer fewer raisins.'),
        (17, 5.0, N'Chloe', N'Cooks perfectly, great nutty flavor.'),
        (17, 4.5, N'Dylan', N'Excellent protein content, love it.'),
        (17, 4.5, N'Ella', N'Best quinoa I''ve tried.'),
        (18, 4.5, N'Finn', N'Great oats, cook quickly and evenly.'),
        (18, 4.0, N'Gabi', N'Good quality, nice texture.'),
        (18, 4.5, N'Hugo', N'Reliable everyday oats.'),
        (19, 4.5, N'Irene', N'Nice chewy texture, great organic choice.'),
        (19, 4.5, N'Jake', N'Good quality, cooks evenly.'),
        (19, 4.5, N'Kara', N'Love the organic certification.'),
        (20, 4.0, N'Lars', N'Great texture, a bit longer to cook.'),
        (20, 3.5, N'Mona', N'Takes forever to cook but tastes good.'),
        (20, 4.0, N'Ned', N'Hearty and filling.'),
        (21, 5.0, N'Opal', N'Delicate flavor, very smooth.'),
        (21, 4.5, N'Phil', N'Best green tea I''ve had, very fresh.'),
        (21, 4.5, N'Quinn', N'Great quality, calming and tasty.'),
        (22, 4.0, N'Rose', N'Very soothing before bed.'),
        (22, 4.5, N'Seth', N'Lovely floral notes, very relaxing.'),
        (22, 4.0, N'Tess', N'Good chamomile, nice and mild.'),
        (23, 5.0, N'Uri', N'Best coffee I''ve ever brewed at home.'),
        (23, 4.5, N'Vera', N'Amazing single-origin flavor.'),
        (23, 4.5, N'Will', N'Very smooth with great aroma.'),
        (23, 5.0, N'Xara', N'Exceptional quality, worth every penny.'),
        (24, 4.0, N'Yael', N'Strong and bold, perfect espresso.'),
        (24, 4.0, N'Zion', N'Good dark roast, consistent grind.'),
        (24, 4.0, N'Abe', N'Solid everyday espresso blend.'),
        (25, 4.5, N'Beth', N'Delicious and not too sweet.'),
        (25, 4.5, N'Cole', N'Great texture, love the almonds.'),
        (25, 4.5, N'Dana', N'My go-to breakfast granola.'),
        (26, 4.0, N'Earl', N'Light and crispy, good for dieting.'),
        (26, 3.5, N'Faye', N'A bit bland but does the job.'),
        (26, 4.0, N'Glen', N'Good value, decent snack.'),
        (27, 5.0, N'Hope', N'So sweet and chewy, love these!'),
        (27, 4.5, N'Ivan', N'Great that there''s no added sugar.'),
        (27, 4.5, N'Jade', N'Perfect snack, very natural taste.'),
        (28, 4.0, N'Kent', N'Good mix, great for hiking.'),
        (28, 3.5, N'Luna', N'Too many M&Ms, prefer less candy.'),
        (28, 3.5, N'Marc', N'Decent but not my favorite mix.'),
        (29, 4.5, N'Nina', N'Great in coffee, smooth texture.'),
        (29, 4.5, N'Omar', N'Love the organic certification.'),
        (29, 4.5, N'Pam', N'Tastes great and not too thin.'),
        (30, 4.5, N'Rex', N'Perfect for lattes, froths well.'),
        (30, 4.0, N'Sara', N'Good oat milk, slightly sweet.'),
        (30, 4.5, N'Tom', N'Best barista oat milk I''ve tried.'),
        (31, 4.5, N'Una', N'Creamy and rich, great for curries.'),
        (31, 4.5, N'Vito', N'Full fat and delicious.'),
        (31, 4.5, N'Wren', N'Perfect coconut milk, great quality.'),
        (32, 4.0, N'Xio', N'Good protein content, mild flavor.'),
        (32, 3.5, N'Yosef', N'Slightly thin but good for cereal.'),
        (32, 3.5, N'Zola', N'Decent soy milk, nothing special.');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
