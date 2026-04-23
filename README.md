
# 📊 SEA Economic Growth Analysis (2000–2023): End-to-End Data Project

## 1. Tóm tắt Dự án (Executive Summary)
Dự án này là một hệ thống phân tích dữ liệu vĩ mô toàn diện, theo dõi hành trình phát triển kinh tế của 10 quốc gia khu vực Đông Nam Á (SEA) trong hơn hai thập kỷ (2000–2023). 

Mục tiêu của dự án không chỉ dừng lại ở việc trực quan hóa các chỉ số thống kê, mà còn nhằm giải quyết bài toán cốt lõi cho các nhà đầu tư: **Đánh giá rủi ro chu kỳ, bóc tách chất lượng tăng trưởng thực tế và xây dựng mô hình xếp hạng tiềm năng thị trường (Scoring Model).**

**Công cụ & Công nghệ sử dụng:**
* **ETL Pipeline:** Python (Pandas, SQLAlchemy, PyODBC).
* **Database & Analytics:** Microsoft SQL Server (T-SQL, Window Functions, CTEs).
* **Data Visualization & Storytelling:** Power BI.
* **Nguồn dữ liệu:** World Bank Open Data (GDP, FDI, Population, Inflation, Unemployment).

## 2. Cấu trúc Thư mục (Repository Structure)
Dựa trên kiến trúc thực tế của dự án:
```text
SEA_Economic_Project/
├── 📁 data/                                     # Chứa các file raw CSV (Metadata, GDP, FDI, CPI...) từ World Bank.
├── 📄 CREATE_DATABASE.sql                       # Script khởi tạo Database, thiết lập Schema và các ràng buộc (Foreign Keys, Cascade).
├── 📄 ETL.ipynb                                 # Pipeline xử lý dữ liệu thô (Unpivot, Data Cleaning, Load to SQL).
├── 📄 Queries_analysis.sql                      # Chứa logic phân tích chuyên sâu (CAGR, Rolling Avg, Scoring Model).
└── 📄 Southeast Asia Economy Analysis.pbix      # File Power BI Dashboard.
```
---
## 3. Quy trình Triển khai (Methodology)

### Giai đoạn 1: Kỹ thuật Dữ liệu (Data Engineering - `etl.ipynb`)
Dữ liệu gốc từ World Bank thường ở định dạng Wide-format (năm trải dài theo cột). Quy trình ETL tự động hóa các bước:

- **Data Reshaping:** Sử dụng hàm `melt()` để Unpivot dữ liệu về dạng Long-format chuẩn Relational Database.  
- **Data Cleansing:** Xử lý giá trị Missing (`NaN`), loại bỏ dữ liệu trùng lặp (`duplicates`).  
- **Outlier Detection:** Xây dựng logic phát hiện biến động GDP bất thường (>50% YoY) để kiểm soát chất lượng dữ liệu.  
- **Data Normalization:** Chuẩn hóa toàn bộ các chỉ số tiền tệ (GDP, FDI) về đơn vị **Tỷ USD (Billion USD)** để tối ưu hóa hiệu năng truy vấn và báo cáo.  

### Giai đoạn 2: Phân tích Dữ liệu Nâng cao (Advanced SQL Analytics - `Queries_analysis.sql`)
Áp dụng các kỹ thuật T-SQL phức tạp để khám phá Insights:

- **Tăng trưởng kép (CAGR):** Áp dụng hàm toán học `POWER()` kết hợp aggregate functions để tính tốc độ tăng trưởng dài hạn 23 năm.  
- **Window Functions:** Sử dụng `LAG()` để tính biến động YoY, `AVG() OVER` để làm mịn xu hướng bằng trung bình trượt 3 năm (Rolling Average).  
- **Đo lường rủi ro:** Tính toán độ lệch chuẩn `STDEV()` để xác định chỉ số biến động kinh tế (Volatility Score).  
- **Mô hình chấm điểm (Scoring Model):** Sử dụng thuật toán phân vị `NTILE(5)` để xếp hạng khách quan tiềm năng đầu tư dựa trên 4 biến số độc lập.  


## 4. Insights Chiến lược & Kết luận (Key Findings)

Dự án đã bóc tách thành công 3 thông điệp chiến lược (Data Storytelling):

1. **Sự dịch chuyển chuỗi cung ứng:**  
   Việt Nam và Cambodia xác lập vị thế "đầu tàu" tăng trưởng mới của khu vực với mức CAGR duy trì ổn định ~6.5 - 7% trong 24 năm qua. Đi kèm với đó là hiệu ứng trễ (Time-lag effect) rõ rệt: dòng vốn FDI đổ vào có tác động thúc đẩy mạnh mẽ GDP sau 1-2 năm.  

2. **Rủi ro lạm phát & Chất lượng tăng trưởng:**  
   Tăng trưởng danh nghĩa có thể đánh lừa nhà đầu tư. Bằng cách tính toán **Real GDP Growth** (Nominal - Inflation), dữ liệu cảnh báo về rủi ro suy giảm sức mua tại một số quốc gia (điển hình như Lào năm 2023) dù GDP danh nghĩa vẫn báo cáo dương.  

3. **Bản đồ Tiềm năng Đầu tư 2026+:**  
   Dựa trên mô hình thuật toán SQL `NTILE(5)` tổng hợp (GDP, FDI, Lạm phát, Dân số):  
   - **Indonesia (#1):** Lựa chọn tối ưu cho các ngành Retail/Tiêu dùng nội địa nhờ quy mô dân số tuyệt đối.  
   - **Việt Nam (#2):** Điểm đến chiến lược cho chuỗi cung ứng toàn cầu nhờ sự cân bằng xuất sắc giữa dòng vốn FDI và tốc độ phát triển vĩ mô.  

---

## 5. Hệ thống Dashboard (Power BI)

*(Khuyến nghị: Chèn các hình ảnh chụp màn hình Power BI của bạn vào các mục dưới đây trên GitHub)*

- **Overview Dashboard:** Bức tranh toàn cảnh về quy mô $50.4T của khu vực và điểm nhấn về các chu kỳ khủng hoảng.  
- **Country Economic Profile:** Phân tích sâu (Drill-down) từng quốc gia với mối tương quan giữa quy mô kinh tế, lạm phát và FDI.  
- **Risk & Resilience:** Ma trận rủi ro (Inflation vs. Unemployment) và biểu đồ đo lường sức bật (Recovery Rate) sau đại dịch COVID-19.  

*Báo cáo được thực hiện với mục đích xây dựng Portfolio Phân tích Dữ liệu. Các nhận định dựa trên số liệu lịch sử công khai từ World Bank.*
