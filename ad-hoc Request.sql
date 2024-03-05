USE retail_events_db;
/* 1. Provide a list of products with a base price greater than 500 and that are featured in promo type
 of 'BOGOF' (Buy One Get One Free). This information will help us identify high-value products that are currently 
being heavily discounted, which can be useful for evaluating our pricing and promotion strategies.*/

SELECT p.product_code, e.product_name, p.base_price, p.promo_type
FROM fact_events p
JOIN dim_products e ON p.product_code = e.product_code
WHERE p.base_price > 500
AND p.promo_type = 'BOGOF';


/*2.Generate a report that provides an overview of the number of stores in each city. 
The results will be sorted in descending order of store counts, allowing us to identify 
the cities with the highest store presence.The report includes two essential fields: 
city and store count, which will assist in optimizing our retail operations.*/

SELECT city, COUNT(store_id) AS store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;


/*3. Generate a report that displays each campaign along with the total revenue generated 
before and after the campaign? The report includes three key fields: campaign_name, 
totaI_revenue(before_promotion), totaI_revenue(after_promotion). This report should help 
in evaluating the financial impact of our promotional campaigns. (Display the values in millions)*/
SELECT 
    c.campaign_name,
    ROUND(SUM(e.base_price * e.`quantity_sold(before_promo)` ) / 1000000, 2) AS total_revenue_before_promotion_inMillion,
    ROUND(SUM(e.base_price * e.`quantity_sold(after_promo)`) / 1000000, 2) AS total_revenue_after_promotion_inMillion
FROM 
    dim_campaigns c
LEFT JOIN 
    fact_events e ON c.campaign_id = e.campaign_id
GROUP BY 
    c.campaign_name;

/*4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for 
each category during the Diwali campaign. Additionally, provide rankings for the 
categories based on their ISU%. The report will include three key fields: 
category, isu%, and rank order. This information will assist in assessing the 
category-wise success and impact of the Diwali campaign on incremental sales.*/

WITH DiwaliCampaign AS (
    SELECT 
        p.category,
        SUM(e.`quantity_sold(before_promo)`) AS total_quantity_before_promo,
        SUM(e.`quantity_sold(after_promo)`) AS total_quantity_after_promo
    FROM 
        fact_events e
    JOIN 
        dim_products p ON e.product_code = p.product_code
    JOIN 
        dim_campaigns c ON e.campaign_id = c.campaign_id
    WHERE 
        c.campaign_name = 'Diwali'
    GROUP BY 
        p.category
)
SELECT 
    category,
    ROUND((total_quantity_after_promo - total_quantity_before_promo) / total_quantity_before_promo * 100, 2) AS isu_percentage,
    RANK() OVER (ORDER BY (total_quantity_after_promo - total_quantity_before_promo) / total_quantity_before_promo DESC) AS rank_order
FROM 
    DiwaliCampaign;
    
/*5. Create a report featuring the Top 5 products, ranked by Incremental Revenue 
Percentage (IR%), across all campaigns. The report will provide essential 
information including product name, category, and ir%. This analysis helps identify 
the most successful products in terms of incremental revenue across our campaigns, 
assisting in product optimization.*/

WITH ProductIR AS (
    SELECT 
        p.product_name,
        p.category,
        ROUND(((SUM(e.base_price * e.`quantity_sold(after_promo)`) / SUM(e.base_price * e.`quantity_sold(before_promo)`)) - 1) * 100, 2) AS IR_percentage,
        RANK() OVER (ORDER BY ((SUM(e.base_price * e.`quantity_sold(after_promo)`) / SUM(e.base_price * e.`quantity_sold(before_promo)`)) - 1) * 100 DESC) AS rank_order
    FROM 
        fact_eventS e
    JOIN 
        dim_products p ON e.product_code = p.product_code
    GROUP BY 
        p.product_name, p.category
)
SELECT 
    product_name,
    category,
    IR_percentage
FROM 
    ProductIR
WHERE 
    rank_order <= 5;

    


