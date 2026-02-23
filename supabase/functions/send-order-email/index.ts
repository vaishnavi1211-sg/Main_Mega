// import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// import { Resend } from 'npm:resend@2.0.0'
// import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

// const corsHeaders = {
//   'Access-Control-Allow-Origin': '*',
//   'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
//   'Content-Type': 'application/json',
// }

// serve(async (req) => {
//   // Handle CORS preflight
//   if (req.method === 'OPTIONS') {
//     return new Response('ok', { headers: corsHeaders })
//   }

//   try {
//     const { orderId, email, orderNumber } = await req.json()

//     // Validate
//     if (!orderId) {
//       return new Response(
//         JSON.stringify({ error: 'Order ID is required' }),
//         { status: 400, headers: corsHeaders }
//       )
//     }

//     // Initialize Supabase client with service role
//     const supabaseClient = createClient(
//       Deno.env.get('SUPABASE_URL') ?? '',
//       Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
//       {
//         auth: {
//           autoRefreshToken: false,
//           persistSession: false
//         }
//       }
//     )

//     // Fetch order details
//     const { data: order, error: orderError } = await supabaseClient
//       .from('emp_mar_orders')
//       .select('*')
//       .eq('id', orderId)
//       .single()

//     if (orderError || !order) {
//       return new Response(
//         JSON.stringify({ error: 'Order not found' }),
//         { status: 404, headers: corsHeaders }
//       )
//     }

//     // Use provided email or order email
//     const recipientEmail = email || order.customer_email
//     if (!recipientEmail) {
//       return new Response(
//         JSON.stringify({ 
//           success: false, 
//           message: 'Email address is not available for this order' 
//         }),
//         { status: 200, headers: corsHeaders }
//       )
//     }

//     // Generate tracking URL
//     const trackingLink = order.tracking_token 
//       ? `https://yourapp.com/track/${order.tracking_token}`
//       : null

//     // Initialize Resend
//     const resendApiKey = Deno.env.get('RESEND_API_KEY')
//     if (!resendApiKey) {
//       console.warn('RESEND_API_KEY not set, using fallback')
//       return new Response(
//         JSON.stringify({ 
//           success: true, 
//           message: 'Email service not configured, would send to: ' + recipientEmail,
//           trackingToken: order.tracking_token,
//           trackingLink
//         }),
//         { status: 200, headers: corsHeaders }
//       )
//     }

//     const resend = new Resend(resendApiKey)

//     // Generate email HTML
//     const emailHtml = generateEmailHtml(
//       order.order_number || orderNumber || `ORD-${order.id.slice(0, 8)}`,
//       trackingLink,
//       order
//     )

//     // Send email
//     const { data: emailData, error: emailError } = await resend.emails.send({
//       from: Deno.env.get('EMAIL_FROM') || 'Cattle Feed Orders <noreply@cattlefeed.com>',
//       to: [recipientEmail],
//       subject: `Order Confirmed: ${order.order_number || orderNumber}`,
//       html: emailHtml,
//     })

//     if (emailError) {
//       console.error('Resend error:', emailError)
      
//       return new Response(
//         JSON.stringify({ 
//           success: false, 
//           message: 'Failed to send email',
//           error: emailError.message,
//           recipientEmail: recipientEmail
//         }),
//         { status: 200, headers: corsHeaders }
//       )
//     }

//     console.log('Email sent successfully:', emailData)

//     // Update order as email sent
//     await supabaseClient
//       .from('emp_mar_orders')
//       .update({ 
//         email_sent: true,
//         updated_at: new Date().toISOString()
//       })
//       .eq('id', orderId)

//     return new Response(
//       JSON.stringify({ 
//         success: true, 
//         message: 'Email sent successfully',
//         trackingToken: order.tracking_token,
//         trackingLink,
//         emailId: emailData?.id
//       }),
//       { status: 200, headers: corsHeaders }
//     )

//   } catch (error) {
//     console.error('Function error:', error)
//     return new Response(
//       JSON.stringify({ 
//         success: false, 
//         error: error.message 
//       }),
//       { status: 500, headers: corsHeaders }
//     )
//   }
// })

// // Helper function to generate email HTML
// function generateEmailHtml(orderNumber: string, trackingLink: string | null, orderDetails: any): string {
//   return `
//   <!DOCTYPE html>
//   <html lang="en">
//   <head>
//     <meta charset="UTF-8">
//     <meta name="viewport" content="width=device-width, initial-scale=1.0">
//     <title>Order Confirmation</title>
//     <style>
//       * { margin: 0; padding: 0; box-sizing: border-box; }
//       body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif; line-height: 1.6; color: #333; background-color: #f5f5f5; padding: 20px; }
//       .email-container { max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
//       .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px 30px; text-align: center; }
//       .header h1 { font-size: 28px; margin-bottom: 10px; font-weight: 600; }
//       .header p { font-size: 16px; opacity: 0.9; }
//       .content { padding: 40px 30px; }
//       .order-number { background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; margin-bottom: 30px; border-left: 4px solid #667eea; }
//       .order-number h2 { color: #667eea; font-size: 20px; margin-bottom: 5px; }
//       .order-details { background: #f8f9fa; padding: 25px; border-radius: 8px; margin-bottom: 30px; }
//       .detail-row { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid #e9ecef; }
//       .detail-row:last-child { border-bottom: none; }
//       .detail-label { font-weight: 600; color: #495057; }
//       .detail-value { color: #212529; text-align: right; }
//       .tracking-section { text-align: center; margin: 30px 0; }
//       .tracking-button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; padding: 15px 30px; border-radius: 50px; font-weight: 600; font-size: 16px; transition: transform 0.2s; margin: 20px 0; }
//       .tracking-button:hover { transform: translateY(-2px); }
//       .tracking-link { display: block; color: #667eea; word-break: break-all; margin-top: 10px; font-size: 14px; }
//       .footer { text-align: center; padding: 20px; background: #f8f9fa; color: #6c757d; font-size: 14px; }
//       .contact-info { margin-top: 20px; padding-top: 20px; border-top: 1px solid #dee2e6; text-align: center; font-size: 14px; color: #6c757d; }
//       .contact-info a { color: #667eea; text-decoration: none; }
//       @media (max-width: 600px) {
//         .content { padding: 20px; }
//         .header { padding: 30px 20px; }
//         .detail-row { flex-direction: column; align-items: flex-start; }
//         .detail-value { text-align: left; margin-top: 5px; }
//       }
//     </style>
//   </head>
//   <body>
//     <div class="email-container">
//       <div style="text-align: center; padding: 20px; background: white;">
//         <h2 style="color: #667eea; margin: 0;">Cattle Feed Management</h2>
//       </div>
      
//       <div class="header">
//         <h1>🎉 Order Confirmed!</h1>
//         <p>Thank you for your purchase. Your order has been received and is being processed.</p>
//       </div>
      
//       <div class="content">
//         <div class="order-number">
//           <h2>Order Number</h2>
//           <p style="font-size: 24px; font-weight: bold; color: #212529;">${orderNumber}</p>
//           <p style="margin-top: 10px; color: #6c757d;">Keep this number for your reference</p>
//         </div>
        
//         <div class="order-details">
//           <h3 style="color: #495057; margin-bottom: 20px; font-size: 18px;">Order Summary</h3>
          
//           <div class="detail-row">
//             <span class="detail-label">Customer Name</span>
//             <span class="detail-value">${orderDetails.customer_name || 'N/A'}</span>
//           </div>
          
//           <div class="detail-row">
//             <span class="detail-label">Product</span>
//             <span class="detail-value">${orderDetails.feed_category || 'N/A'}</span>
//           </div>
          
//           <div class="detail-row">
//             <span class="detail-label">Quantity</span>
//             <span class="detail-value">${orderDetails.bags || 0} bags</span>
//           </div>
          
//           <div class="detail-row">
//             <span class="detail-label">Weight per Bag</span>
//             <span class="detail-value">${orderDetails.weight_per_bag || 0} ${orderDetails.weight_unit || 'kg'}</span>
//           </div>
          
//           <div class="detail-row">
//             <span class="detail-label">Total Weight</span>
//             <span class="detail-value">${orderDetails.total_weight || 0} ${orderDetails.weight_unit || 'kg'}</span>
//           </div>
          
//           <div class="detail-row">
//             <span class="detail-label">Total Amount</span>
//             <span class="detail-value" style="color: #28a745; font-weight: bold;">
//               ₹${orderDetails.total_price || 0}
//             </span>
//           </div>
          
//           <div class="detail-row">
//             <span class="detail-label">Delivery Address</span>
//             <span class="detail-value">${orderDetails.customer_address || 'N/A'}</span>
//           </div>
          
//           ${orderDetails.district ? `
//           <div class="detail-row">
//             <span class="detail-label">District</span>
//             <span class="detail-value">${orderDetails.district}</span>
//           </div>
//           ` : ''}
          
//           ${orderDetails.remarks ? `
//           <div class="detail-row">
//             <span class="detail-label">Remarks</span>
//             <span class="detail-value">${orderDetails.remarks}</span>
//           </div>
//           ` : ''}
//         </div>
        
//         ${trackingLink ? `
//         <div class="tracking-section">
//           <h3 style="color: #495057; margin-bottom: 20px; font-size: 18px;">Track Your Order</h3>
//           <p style="color: #6c757d; margin-bottom: 20px;">
//             Click the button below to track your order status in real-time
//           </p>
          
//           <a href="${trackingLink}" class="tracking-button" target="_blank">
//             📦 Track My Order
//           </a>
          
//           <p style="color: #6c757d; margin-top: 15px; font-size: 14px;">
//             Or copy this link:
//           </p>
//           <a href="${trackingLink}" class="tracking-link" target="_blank">
//             ${trackingLink}
//           </a>
//         </div>
//         ` : ''}
        
//         <div style="background: #e8f4fd; padding: 20px; border-radius: 8px; margin-top: 30px;">
//           <h4 style="color: #0d6efd; margin-bottom: 15px; font-size: 16px;">📋 What's Next?</h4>
//           <ul style="color: #495057; padding-left: 20px;">
//             <li style="margin-bottom: 8px;">Your order will be processed within 24 hours</li>
//             <li style="margin-bottom: 8px;">You'll receive WhatsApp notifications for status changes</li>
//             <li style="margin-bottom: 8px;">Delivery typically takes 3-5 business days</li>
//             <li>Payment will be collected upon delivery</li>
//           </ul>
//         </div>
//       </div>
      
//       <div class="contact-info">
//         <p style="margin-bottom: 10px;">
//           Need help? Contact our support team:
//         </p>
//         <p style="margin-bottom: 5px;">
//           📞 <a href="tel:${orderDetails.customer_mobile || '+911234567890'}">${orderDetails.customer_mobile || '+91 12345 67890'}</a>
//         </p>
//         <p>
//           📧 <a href="mailto:support@cattlefeed.com">support@cattlefeed.com</a>
//         </p>
//       </div>
      
//       <div class="footer">
//         <p>© ${new Date().getFullYear()} Cattle Feed Management. All rights reserved.</p>
//         <p style="font-size: 12px; margin-top: 10px; color: #adb5bd;">
//           This is an automated email, please do not reply to this address.
//         </p>
//       </div>
//     </div>
//   </body>
//   </html>
//   `
// }