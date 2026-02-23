// import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

// const corsHeaders = {
//   'Access-Control-Allow-Origin': '*',
//   'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
//   'Content-Type': 'application/json',
// }

// // WhatsApp Status Messages
// const STATUS_MESSAGES: Record<string, string> = {
//   pending: 'Your order has been received and is being processed.',
//   packing: 'Great news! Your order is now being packed.',
//   ready_for_dispatch: 'Your order is packed and ready for dispatch.',
//   dispatched: '🚚 Your order has been dispatched! On its way to you.',
//   delivered: '✅ Your order has been delivered successfully.',
//   completed: '🎉 Order completed! Thank you for your business.',
//   cancelled: 'Your order has been cancelled as requested.'
// }

// serve(async (req) => {
//   if (req.method === 'OPTIONS') {
//     return new Response('ok', { headers: corsHeaders })
//   }

//   try {
//     const { orderId, newStatus, notes } = await req.json()

//     if (!orderId || !newStatus) {
//       return new Response(
//         JSON.stringify({ error: 'Order ID and status are required' }),
//         { status: 400, headers: corsHeaders }
//       )
//     }

//     // Initialize Supabase with service role
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

//     // Fetch order
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

//     // Check if customer has mobile number
//     const phone = order.customer_mobile
//     if (!phone) {
//       return new Response(
//         JSON.stringify({ 
//           success: false, 
//           message: 'Customer mobile number not available' 
//         }),
//         { status: 200, headers: corsHeaders }
//       )
//     }

//     // Clean and validate phone number
//     const cleanPhone = phone.toString().replace(/\D/g, '')
//     if (cleanPhone.length < 10) {
//       return new Response(
//         JSON.stringify({ 
//           success: false, 
//           message: 'Invalid phone number format' 
//         }),
//         { status: 200, headers: corsHeaders }
//       )
//     }

//     // Format phone for India (+91)
//     const formattedPhone = cleanPhone.startsWith('91') ? `+${cleanPhone}` : `+91${cleanPhone}`

//     // Generate tracking link
//     const trackingLink = order.tracking_token 
//       ? `https://yourapp.com/track/${order.tracking_token}`
//       : null

//     // Generate WhatsApp message
//     const message = generateWhatsAppMessage(order, newStatus, trackingLink, notes)

//     // For now, we'll just return the message for manual sending
//     // You can later integrate with Twilio or another WhatsApp API
//     return new Response(
//       JSON.stringify({ 
//         success: true, 
//         message: 'WhatsApp message generated for manual sending',
//         customerPhone: formattedPhone,
//         whatsappMessage: message,
//         trackingLink: trackingLink
//       }),
//       { status: 200, headers: corsHeaders }
//     )

//   } catch (error) {
//     console.error('WhatsApp function error:', error)
//     return new Response(
//       JSON.stringify({ 
//         success: false, 
//         error: error.message 
//       }),
//       { status: 500, headers: corsHeaders }
//     )
//   }
// })

// // Generate WhatsApp message
// function generateWhatsAppMessage(order: any, status: string, trackingLink: string | null, notes?: string): string {
//   const statusMsg = STATUS_MESSAGES[status] || 'Your order status has been updated.'
  
//   let message = `*Cattle Feed Management*\n\n`
//   message += `Hello ${order.customer_name},\n\n`
//   message += `*Order Update:* ${status.toUpperCase()}\n`
//   message += `*Order Number:* ${order.order_number || order.id.slice(0, 8)}\n`
//   message += `*Product:* ${order.feed_category}\n`
//   message += `*Quantity:* ${order.bags} bags\n`
//   message += `*Amount:* ₹${order.total_price}\n\n`
//   message += `${statusMsg}\n\n`

//   if (trackingLink) {
//     message += `🔗 *Track Your Order:*\n${trackingLink}\n\n`
//   }

//   if (notes) {
//     message += `📝 *Notes:* ${notes}\n\n`
//   }

//   message += `Thank you for choosing us!\n`
//   message += `For queries, call: +91 9876543210`

//   return message
// }