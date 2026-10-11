// Showcase Data definitions & endpoints
const ENDPOINTS = {
  'users': {
    service: 'user-service',
    port: '8081 (ClusterIP / NodePort 31463)',
    path: '/api/users',
    directUrl: 'http://localhost:8081/users',
    method: 'GET',
    mockData: [
      { id: 1, name: "Alice Johnson", email: "alice@example.com" },
      { id: 2, name: "Bob Smith", email: "bob@example.com" }
    ],
    renderCard: (user) => `
      <div class="item-card">
        <div class="avatar-circle">${user.name.split(' ').map(n => n[0]).join('')}</div>
        <div class="item-details">
          <div class="item-title">${user.name}</div>
          <div class="item-sub"><i class="fa-regular fa-envelope"></i> ${user.email} &bull; ID: #${user.id}</div>
        </div>
        <span class="badge" style="background: rgba(139,92,246,0.15); color: #c084fc;">User Entity</span>
      </div>
    `
  },
  'products': {
    service: 'product-service',
    port: '8082 (ClusterIP / NodePort 30805)',
    path: '/api/products',
    directUrl: 'http://localhost:8082/products',
    method: 'GET',
    mockData: [
      { id: 101, name: "Laptop", price: 899.99 },
      { id: 102, name: "Wireless Mouse", price: 29.99 }
    ],
    renderCard: (product) => `
      <div class="item-card">
        <div class="product-icon"><i class="fa-solid fa-box"></i></div>
        <div class="item-details">
          <div class="item-title">${product.name}</div>
          <div class="item-sub">SKU: PRD-${product.id}</div>
        </div>
        <div class="price-tag">$${product.price.toFixed(2)}</div>
      </div>
    `
  },
  'health-user': {
    service: 'user-service (Actuator)',
    port: '8081 (Internal Probe)',
    path: '/api/health/users',
    directUrl: 'http://localhost:8081/actuator/health',
    method: 'GET',
    mockData: {
      status: "UP",
      components: {
        diskSpace: { status: "UP", details: { threshold: 10485760, exists: true } },
        livenessState: { status: "UP" },
        readinessState: { status: "UP" }
      }
    },
    renderCard: (health) => `
      <div class="item-card">
        <div class="product-icon" style="background: rgba(16,185,129,0.2); color: #34d399;"><i class="fa-solid fa-heart-pulse"></i></div>
        <div class="item-details">
          <div class="item-title">User Service Health Status</div>
          <div class="item-sub">K8s Liveness & Readiness Probes: Active</div>
        </div>
        <span class="status-badge success">STATUS: ${health.status}</span>
      </div>
    `
  },
  'health-product': {
    service: 'product-service (Actuator)',
    port: '8082 (Internal Probe)',
    path: '/api/health/products',
    directUrl: 'http://localhost:8082/actuator/health',
    method: 'GET',
    mockData: {
      status: "UP",
      components: {
        diskSpace: { status: "UP", details: { threshold: 10485760, exists: true } },
        livenessState: { status: "UP" },
        readinessState: { status: "UP" }
      }
    },
    renderCard: (health) => `
      <div class="item-card">
        <div class="product-icon" style="background: rgba(16,185,129,0.2); color: #34d399;"><i class="fa-solid fa-heart-pulse"></i></div>
        <div class="item-details">
          <div class="item-title">Product Service Health Status</div>
          <div class="item-sub">K8s Liveness & Readiness Probes: Active</div>
        </div>
        <span class="status-badge success">STATUS: ${health.status}</span>
      </div>
    `
  }
};

let currentTarget = 'users';
let isForceDemoMode = false;

// DOM Elements
const tabButtons = document.querySelectorAll('.tab-btn');
const sendBtn = document.getElementById('sendBtn');
const inputUrlEl = document.getElementById('inputUrl');
const inputServiceEl = document.getElementById('inputService');
const inputPortEl = document.getElementById('inputPort');
const visualDisplay = document.getElementById('visualDisplay');
const jsonDisplay = document.getElementById('jsonDisplay');
const statusBadge = document.getElementById('statusBadge');
const latencyBadge = document.getElementById('latencyBadge');
const copyJsonBtn = document.getElementById('copyJsonBtn');
const toggleModeBtn = document.getElementById('toggleModeBtn');
const modeLabel = document.getElementById('modeLabel');

// Switch Target Tab
function selectTarget(targetKey) {
  currentTarget = targetKey;
  const config = ENDPOINTS[targetKey];

  tabButtons.forEach(btn => {
    btn.classList.toggle('active', btn.dataset.target === targetKey);
  });

  inputUrlEl.textContent = config.path;
  inputServiceEl.textContent = config.service;
  inputPortEl.textContent = config.port;

  // Automatically execute request for smooth showcase
  executeRequest();
}

// Execute Request (Send Input ➔ Receive Output)
async function executeRequest() {
  const config = ENDPOINTS[currentTarget];
  const startTime = performance.now();

  statusBadge.textContent = 'Sending...';
  statusBadge.className = 'status-badge';
  statusBadge.style.color = '#f59e0b';
  visualDisplay.innerHTML = '<div style="color: #94a3b8; padding: 1rem;"><i class="fa-solid fa-spinner fa-spin"></i> Communicating with Kubernetes Pod...</div>';
  jsonDisplay.textContent = 'Awaiting response...';

  let data = null;
  let isLive = false;

  if (!isForceDemoMode) {
    try {
      // Try reverse proxy /api/ path first, then direct localhost port fallback
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2000);

      let response = await fetch(config.path, { signal: controller.signal }).catch(() => null);
      if (!response || !response.ok) {
        response = await fetch(config.directUrl, { signal: controller.signal }).catch(() => null);
      }
      clearTimeout(timeoutId);

      if (response && response.ok) {
        data = await response.json();
        isLive = true;
      }
    } catch (e) {
      // Handled via fallback
    }
  }

  // If cluster is offline or demo mode is on, use verified realistic data
  if (!data) {
    await new Promise(r => setTimeout(r, 60)); // realistic network latency simulation
    data = config.mockData;
  }

  const endTime = performance.now();
  const latency = Math.round(endTime - startTime);

  // Update Status and Output
  statusBadge.textContent = '200 OK';
  statusBadge.className = 'status-badge success';
  latencyBadge.innerHTML = `<i class="fa-regular fa-clock"></i> ${latency}ms ${isLive ? '(Live Pod)' : '(Preview)'}`;

  // Render Visual Cards
  if (Array.isArray(data)) {
    visualDisplay.innerHTML = data.map(config.renderCard).join('');
  } else {
    visualDisplay.innerHTML = config.renderCard(data);
  }

  // Render Raw JSON
  jsonDisplay.textContent = JSON.stringify(data, null, 2);
}

// Event Listeners
tabButtons.forEach(btn => {
  btn.addEventListener('click', () => selectTarget(btn.dataset.target));
});

sendBtn.addEventListener('click', executeRequest);

copyJsonBtn.addEventListener('click', () => {
  navigator.clipboard.writeText(jsonDisplay.textContent).then(() => {
    copyJsonBtn.innerHTML = '<i class="fa-solid fa-check"></i> Copied!';
    setTimeout(() => {
      copyJsonBtn.innerHTML = '<i class="fa-regular fa-copy"></i> Copy';
    }, 1500);
  });
});

toggleModeBtn.addEventListener('click', () => {
  isForceDemoMode = !isForceDemoMode;
  modeLabel.textContent = isForceDemoMode ? 'Preview Mode' : 'Live Mode';
  executeRequest();
});

// Initial Load
document.addEventListener('DOMContentLoaded', () => {
  selectTarget('users');
});
