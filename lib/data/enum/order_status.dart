enum OrderStatus { 
  draft,          // AI created, items listed, prices are 0.
  awaitingQuote,  // Assigned to a partner, waiting for price updates.
  quoteReceived,  // Partner updated prices, waiting for user payment.
  confirmed,      // User paid. Partner should start preparing.
  preparing,      // (Optional) Partner is packing the order.
  readyForPickup, // Partner finished, waiting for rider.
  assigned,       // Rider assigned.
  outForDelivery, // Rider picked up.
  delivered,      // Done.
  cancelled       // Cancelled at any point.
  }
