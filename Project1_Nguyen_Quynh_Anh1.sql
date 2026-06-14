
--1.Nguồn traffic nào mang lại nhiều đơn hàng nhất?
select top(1) utm_source, count(items_purchased) as Quantity
from orders as o
inner join website_sessions as ws on ws.website_session_id = o.website_session_id
Group by utm_source
order by sum(items_purchased)
--2. Campaign nào mang lại doanh thu cao nhất?
select top(1) sum(price_usd) as Amount, utm_campaign
from orders as o 
inner join website_sessions as ws on ws.website_session_id= o.website_session_id
group by utm_campaign
order by sum(price_usd) DESC
--Khách hàng chủ yếu tìm đến qua nhu cầu chung (từ khóa sản phẩm) chứ không phải tìm đích danh tên thương hiệu, cho thấy tiềm năng mở rộng tệp khách mới rất lớn
--3. Người dùng mobile hay desktop tạo ra nhiều đơn hàng hơn?
select top(1) device_type, count(items_purchased) as Quantity
from orders as o
inner join website_sessions as ws on ws.website_session_id = o.website_session_id
group by device_type
order by count(items_purchased)
--Phần lớn khách hàng chốt đơn trên điện thoại; trải nghiệm hiển thị và thanh toán trên mobile là yếu tố quyết định tiếp.
--4. Tỷ lệ chuyển đổi (session → order) của từng nguồn traffic là bao nhiêu?
select utm_source, count (ws.website_session_id) as Session_Quantity, count(o.items_purchased) as Order_Quantity, count(o.items_purchased)*1.00*100/count (ws.website_session_id)*1.00  as CVR
from   website_sessions as ws
left join orders as o on ws.website_session_id = o.website_session_id
group by utm_source
--Nhóm tìm kiếm (bsearch) và khách tự tìm đến (NULL) có ý định mua hàng cao nhất; nguồn social đang lãng phí traffic vì CVR quá thấp

--5. Tổng doanh thu thực tế sau khi trừ refund là bao nhiêu?
select sum(price_usd) - sum(refund_amount_usd) as [Doanh_thu_thực]
from orders as o
left join order_item_refunds as oir on oir.order_id = o.order_id
--Tổng thu hơn 1.8 triệu USD cho thấy quy mô kinh doanh ổn định và dòng tiền thực tế sau trả hàng vẫn rất lớn
--6. Sản phẩm nào mang lại lợi nhuận cao nhất?
select top(1) product_name, (sum(oi.price_usd) - sum(oi.cogs_usd)) as [Lợi nhuận]
from products as p
inner join order_items as oi on oi.product_id = p.product_id
inner join orders as o on o.order_id = oi.order_id
Group by p.product_name
order by (sum(oi.price_usd) - sum(oi.cogs_usd)) DESC
--Đây là sản phẩm nuôi của cả hệ thống doanh nghiệp
--7. Khách hàng quay lại (repeat) có tỷ lệ mua hàng cao hơn khách mới không?
select  ws.is_repeat_session, count( o.order_id)*1.00*100 / count(distinct ws.website_session_id)*1.00 as CVR
from website_sessions as ws
left join orders  as o on ws.website_session_id = o.website_session_id
group by ws.is_repeat_session
--Khách cũ tin tưởng thương hiệu hơn nên dễ xuống tiền hơn (CVR 7%), cần đẩy mạnh các chương trình tri ân khách cũ.
--8. Sản phẩm chính nào kéo theo nhiều sản phẩm mua kèm nhất?
select top (1) p.product_name, sum(t.sub_count) as [Sản_phẩm_kèm] 
from (
 select o.order_id,
    max(case when oi.is_primary_item = 1 then oi.product_id end) as main_product,
    count(case when oi.is_primary_item = 0 then 1 end) as sub_count
    from order_items as oi
    inner join orders as o on o.order_id = oi.order_id
    group by o.order_id
) as t
inner join products as p on p.product_id = t.main_product
group by p.product_name
order by sum(t.sub_count) desc
--Mr. Fuzzy không chỉ bán chạy mà còn là "mồi nhử" cực tốt để bán thêm các món đồ phụ khác trong cùng đơn hàng.
--9. Sản phẩm nào có tỷ lệ refund cao nhất?
select top 1 max(b.product_id) as [ID sản phẩm], max(b.product_name) as [Tên sản phẩm], count(a.order_item_id) as [Tổng số món hàng bán], count(c.order_item_refund_id) as [Tổng số món bị trả lại],
count(c.order_item_refund_id)*1.00/count(a.order_item_id)*1.00*100 as [Tỷ lệ refund]
from order_items a
	inner join products b on a.product_id=b.product_id
	left join order_item_refunds c on a.order_item_id= c.order_item_id
group by b.product_id
order by count(c.order_item_refund_id)*1.00/count(a.order_item_id)*1.00*100 desc
--quá cao
--10. Top 10 khách hàng mang lại doanh thu cao nhất là ai?
select top(10) user_id, sum(o.price_usd) as amount
from orders as o
group by o.user_id
order by sum(o.price_usd) DESC
--Các khách hàng VIP đang có mức chi tiêu đều đặn cao (>200 USD)
--11. Trung bình mất bao lâu (phút) từ lúc user vào web đến khi đặt hàng?
select AVG( DATEDIFF(minute, ws.created_at, o.created_at)) as time_avg
from website_sessions as ws 
inner join orders as o on o.website_session_id = ws.website_session_id
where o.created_at> ws.created_at
--Khách hàng ra quyết định rất nhanh
--12. Nguồn traffic nào mang lại nhiều khách hàng quay lại nhất?
select top(1) utm_source, count(ws.user_id) as repeat_users
from website_sessions as ws
where is_repeat_session = 1
group by utm_source
order by repeat_users desc
--Khách hàng đã nhớ địa chỉ website và tự quay lại, chứng tỏ độ nhận diện thương hiệu tự nhiên (organic) rất mạnh
--13. Những cặp sản phẩm nào thường được mua cùng trong một đơn hàng?
select max(inf.order_id) as _order_id, max(inf.Main) as Main_, max(inf.Sub) as Sub_, count(inf._Group) as time_bought
from
(
select  Main_Product.order_id, (Main_Product.chính) as Main, Sub_Product.phụ as Sub,
(Case when Main_Product.chính like 'The Birthday Sugar Panda' and Sub_Product.phụ like 'The Forever Love Bear' 
	or Sub_Product.phụ like 'The Birthday Sugar Panda' and Main_Product.chính like 'The Forever Love Bear' then N'nhóm_A1'
	when Main_Product.chính like 'The Birthday Sugar Panda' and Sub_Product.phụ like 'The Hudson River Mini bear' 
	or Sub_Product.phụ like 'The Birthday Sugar Panda' and Main_Product.chính like 'The Hudson River Mini bear' then N'nhóm_B1'
	when Main_Product.chính like'The Birthday Sugar Panda' and Sub_Product.phụ like 'The Original Mr. Fuzzy' 
	or Sub_Product.phụ like'The Birthday Sugar Panda' and Main_Product.chính like 'The Original Mr. Fuzzy' then N'nhóm_C1'
	when Main_Product.chính like 'The Forever Love Bear' and Sub_Product.phụ like 'The Hudson River Mini bear' 
	or Sub_Product.phụ like 'The Forever Love Bear' and Main_Product.chính like 'The Hudson River Mini bear' then N'nhóm_D1'
	when Main_Product.chính like 'The Forever Love Bear'  and Sub_Product.phụ like 'The Original Mr. Fuzzy'  
	or Sub_Product.phụ like 'The Forever Love Bear'  and Main_Product.chính like 'The Original Mr. Fuzzy'  then N'nhóm_E1'
	when Main_Product.chính like 'The Hudson River Mini bear'  and Sub_Product.phụ like 'The Original Mr. Fuzzy' 
	or Sub_Product.phụ like 'The Hudson River Mini bear'  and Main_Product.chính like 'The Original Mr. Fuzzy' then N'nhóm_F1'
else NULL
end) as _Group
from 
(select p.product_name as [chính],  o.order_id as order_id
from products as p 
inner join order_items as oi on oi.product_id = p.product_id
inner join orders as o on o.order_id = oi.order_id
where oi.is_primary_item = 1
) as Main_Product
inner join
(select p.product_name as [phụ], o.order_id as order_id
from products as p 
inner join order_items as oi on oi.product_id = p.product_id
inner join orders as o on o.order_id = oi.order_id
where oi.is_primary_item not in (1)
) as Sub_Product on Main_Product.order_id = Sub_Product.order_id
) as inf
group by inf._Group
order by count(inf._Group) DESC
--chiến thuật bán kèm gấu nhỏ theo gấu lớn cực kỳ hiệu quả, đánh vào tâm lý mua theo bộ của khách hàng.