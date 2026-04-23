USE SEA_EconomicDB;
GO

-- Xóa view cũ nếu đã tồn tại để tránh lỗi
IF OBJECT_ID('vw_sea_economic_data', 'V') IS NOT NULL DROP VIEW vw_sea_economic_data;
GO

CREATE VIEW vw_sea_economic_data AS
SELECT 
    c.country_name,
    c.country_code,
    c.income_group,
    g.year,
    g.gdp_usd AS gdp_billion_usd,
    g.gdp_per_capita_usd AS gdp_per_capita,
    p.population,
    e.inflation_rate,
    e.unemployment_rate,
    e.fdi_usd AS fdi_billion_usd
FROM countries c
-- Sử dụng INNER JOIN để đảm bảo chỉ lấy những năm có dữ liệu GDP
INNER JOIN gdp_data g ON c.country_code = g.country_code
-- LEFT JOIN các bảng còn lại vì có thể một số năm bị thiếu số liệu dân số hoặc chỉ số kinh tế
LEFT JOIN population_data p ON c.country_code = p.country_code AND g.year = p.year
LEFT JOIN economic_indicators e ON c.country_code = e.country_code AND g.year = e.year
WHERE c.country_code IN (
    'VNM', -- Vietnam
    'THA', -- Thailand
    'IDN', -- Indonesia
    'PHL', -- Philippines
    'MYS', -- Malaysia
    'SGP', -- Singapore
    'MMR', -- Myanmar
    'KHM', -- Cambodia
    'LAO', -- Laos
    'BRN'  -- Brunei
);
GO

-- Kiểm tra dữ liệu trong View vừa tạo
SELECT * FROM vw_sea_economic_data ORDER BY country_name, year;

-- Script: 3_Feature_Engineering.sql
-- Mục đích: Tính toán các chỉ số kinh tế nâng cao bằng Window Functions
-- ==============================================================================

WITH base_metrics AS (
    SELECT * FROM vw_sea_economic_data
),
calculated_features AS (
    SELECT 
        *,
        -- ① YoY Growth Rate: Tốc độ tăng trưởng so với năm trước
        (gdp_billion_usd - LAG(gdp_billion_usd) OVER (PARTITION BY country_code ORDER BY year)) 
        / NULLIF(LAG(gdp_billion_usd) OVER (PARTITION BY country_code ORDER BY year), 0) AS yoy_growth_rate,

        -- ③ Rolling Average 3 năm: Làm mịn biến động ngắn hạn
        AVG(gdp_billion_usd) OVER (
            PARTITION BY country_code 
            ORDER BY year 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS gdp_rolling_avg_3y,

        -- ④ GDP Share: Tỷ trọng GDP của quốc gia trong toàn khu vực theo từng năm
        gdp_billion_usd / SUM(gdp_billion_usd) OVER (PARTITION BY year) AS regional_gdp_share,

        -- ⑤ Dynamic Rank: Thứ hạng kinh tế trong khu vực thay đổi theo từng năm
        DENSE_RANK() OVER (PARTITION BY year ORDER BY gdp_billion_usd DESC) AS regional_rank
    FROM base_metrics
)
SELECT 
    *,
    -- ⑥ Phân loại tăng trưởng (Growth Label)
    CASE 
        WHEN yoy_growth_rate > 0.07 THEN 'Boom'
        WHEN yoy_growth_rate BETWEEN 0.03 AND 0.07 THEN 'Stable'
        WHEN yoy_growth_rate BETWEEN 0 AND 0.03 THEN 'Slow'
        WHEN yoy_growth_rate < 0 THEN 'Recession'
        ELSE 'N/A'
    END AS growth_label,

    -- ⑦ Phân loại thu nhập (GDP per Capita Tier)
    CASE 
        WHEN gdp_per_capita > 12535 THEN 'High Income'
        WHEN gdp_per_capita BETWEEN 4046 AND 12535 THEN 'Upper-Middle Income'
        WHEN gdp_per_capita BETWEEN 1036 AND 4045 THEN 'Lower-Middle Income'
        ELSE 'Low Income'
    END AS income_tier
INTO processed_economic_data -- Lưu vào bảng mới để sẵn sàng cho bước Visualization
FROM calculated_features;

-- ② Tính CAGR (Tốc độ tăng trưởng kép) 2000-2023
-- Bước này tính riêng vì nó so sánh điểm đầu và điểm cuối
SELECT 
    country_code,
    country_name,
    POWER(
        CAST(MAX(CASE WHEN year = 2023 THEN gdp_billion_usd END) / 
             NULLIF(MIN(CASE WHEN year = 2000 THEN gdp_billion_usd END), 0) AS FLOAT),
        1.0/23
    ) - 1 AS cagr_2000_2023
FROM vw_sea_economic_data
GROUP BY country_code, country_name;


-- ==============================================================================
-- Script: 4_Analysis_Queries.sql
-- ==============================================================================

-- ==============================================================================
-- Q1. Quốc gia nào tăng trưởng GDP nhanh nhất trung bình giai đoạn 2000–2023?
-- ==============================================================================
SELECT 
    country_name,
    ROUND(AVG(yoy_growth_rate) * 100, 2) AS avg_growth_pct,
    RANK() OVER (ORDER BY AVG(yoy_growth_rate) DESC) AS growth_rank
FROM processed_economic_data
WHERE yoy_growth_rate IS NOT NULL -- Bỏ qua năm 2000 vì không có dữ liệu năm trước để so sánh
GROUP BY country_name;


-- ==============================================================================
-- Q2. Tổng GDP khu vực Đông Nam Á thay đổi thế nào theo thập kỷ?
-- Sử dụng bảng lookup 'decades' đã tạo ở Bước 1
-- ==============================================================================
SELECT 
    d.decade_name,
    ROUND(SUM(p.gdp_billion_usd), 2) AS total_regional_gdp_billion,
    COUNT(DISTINCT p.year) AS years_in_data
FROM processed_economic_data p
JOIN decades d ON p.year BETWEEN d.decade_start AND d.decade_end
GROUP BY d.decade_name
ORDER BY d.decade_name;


-- ==============================================================================
-- Q3. Năm nào có nhiều quốc gia tăng trưởng âm nhất? (Tìm kiếm năm Khủng hoảng)
-- ==============================================================================
SELECT TOP 5
    year,
    COUNT(country_code) AS countries_in_recession,
    STRING_AGG(country_code, ', ') AS list_of_countries -- Liệt kê cụ thể nước nào bị âm
FROM processed_economic_data
WHERE yoy_growth_rate < 0 OR growth_label = 'Recession'
GROUP BY year
ORDER BY countries_in_recession DESC, year DESC;


-- ==============================================================================
-- Q4. Quốc gia nào có tăng trưởng ổn định nhất? (Dựa trên Độ lệch chuẩn - STDEV)
-- ==============================================================================
SELECT 
    country_name,
    ROUND(AVG(yoy_growth_rate) * 100, 2) AS avg_growth_pct,
    ROUND(STDEV(yoy_growth_rate) * 100, 2) AS growth_volatility_score
FROM processed_economic_data
WHERE yoy_growth_rate IS NOT NULL
GROUP BY country_name
-- Lọc bỏ các nước tăng trưởng quá thấp (phải tăng trưởng trung bình > 3% mới xét độ ổn định)
HAVING AVG(yoy_growth_rate) > 0.03 
ORDER BY growth_volatility_score ASC; -- Điểm càng thấp càng ổn định


-- ==============================================================================
-- Q5. Top 3 năm tăng trưởng mạnh nhất và yếu nhất của từng quốc gia
-- ==============================================================================
WITH RankedGrowth AS (
    SELECT 
        country_name,
        year,
        ROUND(yoy_growth_rate * 100, 2) AS growth_pct,
        DENSE_RANK() OVER (PARTITION BY country_code ORDER BY yoy_growth_rate DESC) AS best_rank,
        DENSE_RANK() OVER (PARTITION BY country_code ORDER BY yoy_growth_rate ASC) AS worst_rank
    FROM processed_economic_data
    WHERE yoy_growth_rate IS NOT NULL
)
SELECT 
    country_name,
    year,
    growth_pct,
    CASE 
        WHEN best_rank <= 3 THEN 'Top 3 Best Years'
        WHEN worst_rank <= 3 THEN 'Top 3 Worst Years'
    END AS performance_category
FROM RankedGrowth
WHERE best_rank <= 3 OR worst_rank <= 3
ORDER BY country_name, growth_pct DESC;


-- ==============================================================================
-- Q6. Mối quan hệ giữa FDI và tốc độ tăng trưởng GDP (Hiệu ứng trễ 1 năm)
-- Liệu FDI năm trước có thúc đẩy GDP năm nay?
-- ==============================================================================
SELECT 
    country_name,
    year,
    fdi_billion_usd AS current_fdi,
    LAG(fdi_billion_usd) OVER (PARTITION BY country_code ORDER BY year) AS prev_year_fdi,
    ROUND(yoy_growth_rate * 100, 2) AS current_gdp_growth_pct
FROM processed_economic_data
WHERE country_code = 'VNM' -- Ví dụ soi riêng Việt Nam để dễ thấy trend
ORDER BY year;


-- ==============================================================================
-- Q7. Quốc gia nào đang "bắt kịp" GDP đầu người so với Singapore nhanh nhất?
-- ==============================================================================
WITH SingaporeBaseline AS (
    SELECT year, gdp_per_capita AS sgp_gdp_pc
    FROM processed_economic_data
    WHERE country_code = 'SGP'
)
SELECT 
    p.year,
    p.country_name,
    p.gdp_per_capita,
    s.sgp_gdp_pc,
    ROUND((p.gdp_per_capita / s.sgp_gdp_pc) * 100, 2) AS pct_of_singapore_gdp
FROM processed_economic_data p
JOIN SingaporeBaseline s ON p.year = s.year
WHERE p.country_code != 'SGP'
-- Chỉ xem các năm mốc để thấy sự dịch chuyển dài hạn
AND p.year IN (2000, 2010, 2023) 
ORDER BY p.country_name, p.year;


-- ==============================================================================
-- Q8. Lạm phát có ăn mòn tăng trưởng GDP thực không? (Phân tích năm 2023)
-- Real GDP Growth = Nominal Growth - Inflation Rate
-- ==============================================================================
SELECT 
    country_name,
    ROUND(yoy_growth_rate * 100, 2) AS nominal_growth_pct,
    inflation_rate,
    ROUND((yoy_growth_rate * 100) - COALESCE(inflation_rate, 0), 2) AS real_growth_pct,
    RANK() OVER (ORDER BY yoy_growth_rate DESC) AS nominal_rank,
    RANK() OVER (ORDER BY ((yoy_growth_rate * 100) - COALESCE(inflation_rate, 0)) DESC) AS real_rank
FROM processed_economic_data
WHERE year = 2023
ORDER BY real_rank;


-- ==============================================================================
-- Q10. Market Potential Score — Xếp hạng tổng hợp quốc gia đáng đầu tư nhất (2023)
-- Chấm điểm (Scoring Model) dựa trên 4 yếu tố vĩ mô
-- ==============================================================================
WITH ScoringData AS (
    SELECT 
        country_name,
        -- Điểm Tăng trưởng (Càng cao càng tốt)
        NTILE(5) OVER (ORDER BY yoy_growth_rate ASC) AS growth_score,
        -- Điểm Lạm phát (Càng thấp càng tốt -> ORDER BY DESC để lạm phát thấp được điểm cao)
        NTILE(5) OVER (ORDER BY inflation_rate DESC) AS inflation_score,
        -- Điểm FDI (Càng lớn càng tốt)
        NTILE(5) OVER (ORDER BY fdi_billion_usd ASC) AS fdi_score,
        -- Điểm quy mô thị trường/Dân số (Càng đông càng tốt cho retail)
        NTILE(5) OVER (ORDER BY population ASC) AS pop_score
    FROM processed_economic_data
    WHERE year = 2023 AND yoy_growth_rate IS NOT NULL
)
SELECT 
    country_name,
    growth_score,
    inflation_score,
    fdi_score,
    pop_score,
    (growth_score + inflation_score + fdi_score + pop_score) AS total_potential_score,
    DENSE_RANK() OVER (ORDER BY (growth_score + inflation_score + fdi_score + pop_score) DESC) AS final_investment_rank
FROM ScoringData
ORDER BY final_investment_rank;

