// import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

// const corsHeaders = {
//   "Access-Control-Allow-Origin": "*",
//   "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
// };

// serve(async (req: { method: string; json: () => PromiseLike<{ order_id: any; }> | { order_id: any; }; }) => {
//   // Handle CORS preflight requests
//   if (req.method === "OPTIONS") {
//     return new Response("ok", { headers: corsHeaders });
//   }

//   try {
//     const { order_id } = await req.json();

//     if (!order_id) {
//       throw new Error("Order ID is required");
//     }

//     const supabaseClient = createClient(
//       Deno.env.get("SUPABASE_URL") ?? "",
//       Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
//     );

//     console.log("Generating invoice for order:", order_id);

//     // 1. Get order details
//     const { data: order, error: orderError } = await supabaseClient
//       .from("emp_mar_orders")
//       .select("*")
//       .eq("id", order_id)
//       .single();

//     if (orderError) {
//       console.error("Error fetching order:", orderError);
//       throw orderError;
//     }

//     // 2. Generate simple HTML invoice
//     const invoiceHTML = `
//       <!DOCTYPE html>
//       <html>
//       <head>
//         <title>Invoice - ${order.tracking_id}</title>
//         <style>
//           body { font-family: Arial, sans-serif; margin: 40px; }
//           .header { text-align: center; margin-bottom: 30px; }
//           .details { margin: 20px 0; }
//           .table { width: 100%; border-collapse: collapse; margin: 20px 0; }
//           .table th, .table td { border: 1px solid #ddd; padding: 8px; }
//           .total { text-align: right; font-size: 18px; font-weight: bold; }
//           .footer { margin-top: 40px; text-align: center; font-size: 12px; color: #666; }
//         </style>
//       </head>
//       <body>
//         <div class="header">
//           <h1>INVOICE</h1>
//           <p>Order #${order.tracking_id}</p>
//         </div>
        
//         <div class="details">
//           <p><strong>Customer:</strong> ${order.customer_name}</p>
//           <p><strong>Mobile:</strong> ${order.customer_mobile}</p>
//           ${order.customer_email ? `<p><strong>Email:</strong> ${order.customer_email}</p>` : ""}
//           <p><strong>Address:</strong> ${order.customer_address}</p>
//           <p><strong>District:</strong> ${order.district}</p>
//           <p><strong>Date:</strong> ${new Date(order.created_at).toLocaleDateString()}</p>
//         </div>
        
//         <table class="table">
//           <tr>
//             <th>Product</th>
//             <th>Bags</th>
//             <th>Weight/Bag</th>
//             <th>Price/Bag</th>
//             <th>Total</th>
//           </tr>
//           <tr>
//             <td>${order.feed_category}</td>
//             <td>${order.bags}</td>
//             <td>${order.weight_per_bag} ${order.weight_unit}</td>
//             <td>₹${order.price_per_bag}</td>
//             <td>₹${order.total_price}</td>
//           </tr>
//         </table>
        
//         <div class="total">
//           <p>Total Amount: ₹${order.total_price}</p>
//         </div>
        
//         <div class="footer">
//           <p>Thank you for your business!</p>
//           <p>Track your order: https://mega-pro-track.vercel.app/#/track/${order.tracking_id}</p>
//         </div>
//       </body>
//       </html>
//     `;

//     // 3. Upload to Supabase Storage
//     const fileName = `invoice-${order.tracking_id}.html`;
//     const { error: uploadError } = await supabaseClient.storage
//       .from("invoices")
//       .upload(fileName, invoiceHTML, {
//         contentType: "text/html",
//         upsert: true,
//       });

//     if (uploadError) {
//       console.error("Error uploading invoice:", uploadError);
//       throw uploadError;
//     }

//     // 4. Get public URL
//     const { data: { publicUrl } } = supabaseClient.storage
//       .from("invoices")
//       .getPublicUrl(fileName);

//     console.log("Invoice URL:", publicUrl);

//     // 5. Update order with invoice URL
//     const { error: updateError } = await supabaseClient
//       .from("emp_mar_orders")
//       .update({
//         invoice_url: publicUrl,
//         invoice_generated_at: new Date().toISOString(),
//       })
//       .eq("id", order_id);

//     if (updateError) {
//       console.error("Error updating order:", updateError);
//       throw updateError;
//     }

//     // 6. Return success response
//     return new Response(
//       JSON.stringify({
//         success: true,
//         invoice_url: publicUrl,
//         tracking_id: order.tracking_id,
//       }),
//       {
//         headers: { ...corsHeaders, "Content-Type": "application/json" },
//       }
//     );
//   } catch (error) {
//     console.error("Error in generate-invoice function:", error);
//     return new Response(
//       JSON.stringify({
//         success: false,
//         error: error.message,
//       }),
//       {
//         status: 500,
//         headers: { ...corsHeaders, "Content-Type": "application/json" },
//       }
//     );
//   }
// });