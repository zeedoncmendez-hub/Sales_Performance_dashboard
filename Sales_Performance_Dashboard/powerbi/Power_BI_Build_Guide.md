# Power BI build guide

This guide walks you through building the dashboard in **Power BI Desktop** (free, Windows) from the files in this project. It takes about 1–2 hours the first time. When you are done, save the report as `powerbi/Superstore_Sales_Dashboard.pbix` and take a screenshot for `images/`.

`images/dashboard_preview.png` shows the target layout, drawn with the same numbers your dashboard will show. Use it as your reference.

---

## 1. Load the data

You have two options. Option A is quicker; option B shows the full SQL-to-Power-BI workflow, which is good to talk about in interviews.

**Option A: CSV files**
1. Open Power BI Desktop and choose **Get data > Text/CSV**.
2. Load all five files from `powerbi/model_data/`: `fact_sales`, `dim_date`, `dim_customer`, `dim_product`, `dim_location`.
3. For each one, click **Transform Data** first and check the column types in Power Query:
   - `dim_date[full_date]` → Date
   - `fact_sales[sales]`, `fact_sales[profit]` → Decimal number
   - `fact_sales[discount]` → Decimal number
   - `dim_location[postal_code]` → Text (keeps leading zeros)
4. Click **Close & Apply**.

**Option B: straight from MySQL**
1. Run the three scripts in `sql/` (see the main README).
2. In Power BI choose **Get data > MySQL database**, server `localhost`, database `superstore_db`.
3. Select `fact_sales` and the four `dim_` tables and load them. (You may need to install the MySQL Connector/NET the first time; Power BI shows a link.)

## 2. Build the model (star schema)

Go to **Model view** and make sure these relationships exist. All are *many-to-one, single direction*, from the fact table to the dimension:

| From (many) | To (one) |
|---|---|
| `fact_sales[order_date_key]` | `dim_date[date_key]` |
| `fact_sales[customer_key]` | `dim_customer[customer_key]` |
| `fact_sales[product_key]` | `dim_product[product_key]` |
| `fact_sales[location_key]` | `dim_location[location_key]` |

Power BI may auto-detect some of these; delete any it creates that are not in the table.

Then:
- Select `dim_date` → **Table tools > Mark as date table** → choose `full_date`. Time-intelligence measures need this.
- Select `dim_date[month_name]` → **Column tools > Sort by column** → `month_num`, so months sort Jan–Dec.
- Hide the key columns (`*_key`) from report view (right-click > Hide in report view). It keeps the field list clean.

## 3. Add the measures

1. **Home > Enter data**, name the table `_Measures`, click **Load**.
2. Select `_Measures`, then **Modeling > New measure** and paste each measure from `DAX_measures.dax`, one at a time.
3. Format them: `Total Sales`, `Total Profit`, `Avg Order Value` as Currency with 0 decimals; every `%` measure as Percentage with 1 decimal.
4. Add the **Discount Band** calculated column to `fact_sales` (it's at the bottom of the DAX file).

**Check your work:** put `Total Sales` in a card. It must read **$2,297,201**. `Total Profit` must read **$286,397**, and `Total Orders` must read **5,009**. If not, a relationship or data type is wrong.

## 4. Build the report page

Canvas: 16:9. Use one consistent colour theme (View > Themes).

**Top row: KPI cards**
`Total Sales` · `Total Profit` · `Profit Margin %` · `Total Orders` · `Avg Order Value`

**Middle row**
- **Line and clustered column chart**: X-axis `dim_date[year_num]`, columns `Total Sales`, line `Profit Margin %`.
- **Clustered bar chart**: Y-axis `dim_location[region]`, X-axis `Total Profit`.

**Bottom row**
- **Bar chart**: Y-axis `dim_product[sub_category]`, X-axis `Total Profit`, sorted ascending. Add conditional formatting (Format > Bars > fx): red when `Total Profit` < 0.
- **Column chart**: X-axis `fact_sales[Discount Band]`, Y-axis `Profit Margin %`.
- **Line chart**: X-axis `dim_date[month_name]`, Y-axis `Total Sales`, Legend `dim_date[year_num]`.

**Slicers (left side or top)**
`dim_date[year_num]` · `dim_location[region]` · `dim_customer[segment]` · `dim_product[category]`

**Finishing touches**
- Title text box: "Superstore Sales Performance, 2014–2017".
- Turn on tooltips with `Total Sales`, `Total Profit`, `Profit Margin %`.
- Test the slicers: pick Central region and confirm the margin drops to about 7.9%.

## 5. Optional extras (good interview talking points)

- **Drill-through page**: a detail page for one sub-category, showing its products and their profit, opened by right-clicking a bar.
- **Top N filter**: show only the 10 most profitable products (Filters pane > Top N).
- **Map visual**: `dim_location[state]` coloured by `Profit Margin %`.

## 6. Save and publish

- Save as `powerbi/Superstore_Sales_Dashboard.pbix`.
- Export a screenshot (or **File > Export > PDF**) into `images/`.
- Optional: publish to the Power BI service and add the link to your README and LinkedIn.
