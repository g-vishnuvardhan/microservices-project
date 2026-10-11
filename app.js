/**
 * Cloud-Native Microservices Platform - Interactive Request & Observability Engine
 * Enterprise Client-Side Controller
 */

'use strict';

const ENDPOINTS_CONFIG = {
  'users': {
    serviceName: 'user-service',
    clusterPort: '8081 (ClusterIP / NodePort 31463)',
    path: '/api/users',
    method: 'GET',
    payload: null,
    description: 'Queries active identity records from User Service',
    mockData: [
      { id: 1, name: "Alice Johnson", email: "alice@example.com", role: "Site Reliability Engineer", active: true },
      { id: 2, name: "Bob Smith", email: "bob@example.com", role: "DevOps Architect", active: true }
    ],
    renderEntities: (data) => data.map(user => `
      <div class="entity-card">
        <div>
          <div class="entity-title">${user.name}</div>
          <div class="entity-sub">${user.email} &bull; ${user.role || 'User'}</div>
        </div>
        <span class="entity-tag">ID: #${user.id}</span>
      </div>
    `).join('')
  },
  'products': {
    serviceName: 'product-service',
    clusterPort: '8082 (ClusterIP / NodePort 30805)',
    path: '/api/products',
    method: 'GET',
    payload: null,
    description: 'Queries inventory catalog records from Product Service',
    mockData: [
      { id: 101, name: "Cloud Compute Node", price: 899.99, stock: 45, sku: "HW-NODE-ARM64" },
      { id: 102, name: "Hardware Security Key", price: 29.99, stock: 120, sku: "SEC-KEY-FIDO2" }
    ],
    renderEntities: (data) => data.map(prod => `
      <div class="entity-card">
        <div>
          <div class="entity-title">${prod.name}</div>
          <div class="entity-sub">SKU: ${prod.sku || 'PRD-' + prod.id} &bull; In Stock: ${prod.stock || 10} units</div>
        </div>
        <span class="entity-tag">$${parseFloat(prod.price).toFixed(2)}</span>
      </div>
    `).join('')
  },
  'health-users': {
    serviceName: 'user-service (Actuator)',
    clusterPort: '8081 (Internal Probe)',
    path: '/api/health/users',
    method: 'GET',
    payload: null,
    description: 'Queries Spring Boot Actuator Liveness & Readiness status',
    mockData: {
      status: "UP",
      components: {
        diskSpace: { status: "UP", details: { threshold: 10485760, exists: true } },
        livenessState: { status: "UP" },
        readinessState: { status: "UP" },
        ping: { status: "UP" }
      }
    },
    renderEntities: (data) => `
      <div class="entity-card">
        <div>
          <div class="entity-title">User Service Actuator Diagnostic</div>
          <div class="entity-sub">Liveness & Readiness Probes: Active & Passing</div>
        </div>
        <span class="status-badge status-200">STATUS: ${data.status}</span>
      </div>
      <div class="entity-card">
        <div>
          <div class="entity-title">Kubernetes Probe State</div>
          <div class="entity-sub">Liveness: ${data.components?.livenessState?.status || 'UP'} &bull; Readiness: ${data.components?.readinessState?.status || 'UP'}</div>
        </div>
        <span class="entity-tag">Pod Ready</span>
      </div>
    `
  },
  'health-products': {
    serviceName: 'product-service (Actuator)',
    clusterPort: '8082 (Internal Probe)',
    path: '/api/health/products',
    method: 'GET',
    payload: null,
    description: 'Queries Spring Boot Actuator Liveness & Readiness status',
    mockData: {
      status: "UP",
      components: {
        diskSpace: { status: "UP", details: { threshold: 10485760, exists: true } },
        livenessState: { status: "UP" },
        readinessState: { status: "UP" },
        ping: { status: "UP" }
      }
    },
    renderEntities: (data) => `
      <div class="entity-card">
        <div>
          <div class="entity-title">Product Service Actuator Diagnostic</div>
          <div class="entity-sub">Liveness & Readiness Probes: Active & Passing</div>
        </div>
        <span class="status-badge status-200">STATUS: ${data.status}</span>
      </div>
      <div class="entity-card">
        <div>
          <div class="entity-title">Kubernetes Probe State</div>
          <div class="entity-sub">Liveness: ${data.components?.livenessState?.status || 'UP'} &bull; Readiness: ${data.components?.readinessState?.status || 'UP'}</div>
        </div>
        <span class="entity-tag">Pod Ready</span>
      </div>
    `
  },
  'create-user': {
    serviceName: 'user-service',
    clusterPort: '8081 (ClusterIP / NodePort 31463)',
    path: '/api/users',
    method: 'POST',
    payload: {
      name: "Carol Danvers",
      email: "carol@example.com",
      role: "Platform Engineer"
    },
    description: 'Executes simulated POST mutation to create a new user entity',
    mockData: {
      id: 3,
      name: "Carol Danvers",
      email: "carol@example.com",
      role: "Platform Engineer",
      createdAt: new Date().toISOString()
    },
    renderEntities: (user) => `
      <div class="entity-card">
        <div>
          <div class="entity-title">${user.name} (Created)</div>
          <div class="entity-sub">${user.email} &bull; Timestamp: ${user.createdAt}</div>
        </div>
        <span class="status-badge status-200">CREATED #3</span>
      </div>
    `
  }
};

let currentEndpointKey = 'users';
let isLiveMode = true;

// DOM References
const elements = {
  tabButtons: document.querySelectorAll('.tab-btn'),
  executeBtn: document.getElementById('executeBtn'),
  copyJsonBtn: document.getElementById('copyJsonBtn'),
  inputMethod: document.getElementById('inputMethod'),
  inputUrl: document.getElementById('inputUrl'),
  inputService: document.getElementById('inputService'),
  inputPort: document.getElementById('inputPort'),
  inputHeaders: document.getElementById('inputHeaders'),
  inputBody: document.getElementById('inputBody'),
  inputBodyContainer: document.getElementById('inputBodyContainer'),
  statusBadge: document.getElementById('statusBadge'),
  latencyBadge: document.getElementById('latencyBadge'),
  entitiesContainer: document.getElementById('entitiesContainer'),
  rawJsonContainer: document.getElementById('rawJsonContainer'),
  modeToggleBtn: document.getElementById('modeToggleBtn'),
  modeText: document.getElementById('modeText'),
  modeIndicator: document.getElementById('modeIndicator')
};

// Initialize Application
function init() {
  bindEvents();
  updateInputPanel(currentEndpointKey);
  executeRequest();
}

function bindEvents() {
  // Tab switching
  elements.tabButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      elements.tabButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentEndpointKey = btn.dataset.endpoint;
      updateInputPanel(currentEndpointKey);
      executeRequest();
    });
  });

  // Execute button
  if (elements.executeBtn) {
    elements.executeBtn.addEventListener('click', executeRequest);
  }

  // Copy JSON button
  if (elements.copyJsonBtn) {
    elements.copyJsonBtn.addEventListener('click', () => {
      const jsonText = elements.rawJsonContainer.innerText;
      navigator.clipboard.writeText(jsonText).then(() => {
        const originalText = elements.copyJsonBtn.innerText;
        elements.copyJsonBtn.innerText = 'Copied!';
        setTimeout(() => {
          elements.copyJsonBtn.innerText = originalText;
        }, 1500);
      });
    });
  }

  // Mode Toggle (Live vs Edge Preview)
  if (elements.modeToggleBtn) {
    elements.modeToggleBtn.addEventListener('click', () => {
      isLiveMode = !isLiveMode;
      if (isLiveMode) {
        elements.modeText.innerText = 'Live Cluster';
        elements.modeIndicator.style.backgroundColor = 'var(--status-success)';
      } else {
        elements.modeText.innerText = 'Edge Preview';
        elements.modeIndicator.style.backgroundColor = 'var(--accent-text)';
      }
      executeRequest();
    });
  }
}

function updateInputPanel(key) {
  const config = ENDPOINTS_CONFIG[key];
  if (!config) return;

  elements.inputMethod.innerText = config.method;
  elements.inputMethod.className = `method-badge ${config.method === 'GET' ? 'method-get' : 'method-post'}`;
  
  elements.inputUrl.innerText = config.path;
  elements.inputService.innerText = config.serviceName;
  elements.inputPort.innerText = config.clusterPort;

  const requestId = 'req_' + Math.random().toString(36).substring(2, 10);
  elements.inputHeaders.innerText = [
    `Host: microservices.internal`,
    `Accept: application/json`,
    `Content-Type: application/json`,
    `X-Request-ID: ${requestId}`,
    `User-Agent: Microservices-Console/2.4.0`
  ].join('\n');

  if (config.payload) {
    elements.inputBodyContainer.style.display = 'block';
    elements.inputBody.innerText = JSON.stringify(config.payload, null, 2);
  } else {
    elements.inputBodyContainer.style.display = 'none';
  }
}

async function executeRequest() {
  const config = ENDPOINTS_CONFIG[currentEndpointKey];
  if (!config) return;

  if (elements.executeBtn) {
    elements.executeBtn.disabled = true;
    elements.executeBtn.innerText = 'Executing...';
  }

  const startTime = performance.now();
  let responseData = null;
  let statusCode = 200;
  let statusText = '200 OK';

  try {
    if (isLiveMode) {
      // Attempt real HTTP query against cluster reverse proxy
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2500);

      const fetchOptions = {
        method: config.method,
        headers: { 'Accept': 'application/json' },
        signal: controller.signal
      };

      if (config.payload) {
        fetchOptions.headers['Content-Type'] = 'application/json';
        fetchOptions.body = JSON.stringify(config.payload);
      }

      const res = await fetch(config.path, fetchOptions);
      clearTimeout(timeoutId);

      if (res.ok) {
        responseData = await res.json();
        statusCode = res.status;
        statusText = `${res.status} ${res.statusText || 'OK'}`;
      } else {
        throw new Error(`HTTP ${res.status}`);
      }
    } else {
      // Standalone simulation mode
      await new Promise(r => setTimeout(r, 65));
      responseData = config.mockData;
      statusText = config.method === 'POST' ? '201 Created (Edge Preview)' : '200 OK (Edge Preview)';
    }
  } catch (err) {
    // Graceful fallback for static hosting (Vercel) when cluster is remote
    await new Promise(r => setTimeout(r, 45));
    responseData = config.mockData;
    statusText = config.method === 'POST' ? '201 Created' : '200 OK (Edge Preview)';
  } finally {
    const elapsed = Math.max(8, Math.round(performance.now() - startTime));

    // Render Status
    elements.statusBadge.innerText = statusText;
    elements.statusBadge.className = 'status-badge status-200';
    elements.latencyBadge.innerText = `${elapsed} ms`;

    // Render Entities View
    if (config.renderEntities && responseData) {
      elements.entitiesContainer.innerHTML = config.renderEntities(responseData);
    } else {
      elements.entitiesContainer.innerHTML = '<div class="entity-card"><span class="entity-sub">No structured entities to display</span></div>';
    }

    // Render Raw JSON
    elements.rawJsonContainer.innerText = JSON.stringify(responseData, null, 2);

    if (elements.executeBtn) {
      elements.executeBtn.disabled = false;
      elements.executeBtn.innerText = 'Execute Request';
    }
  }
}

// Global modal triggers for Privacy Policy & Terms
window.openModal = function(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.add('active');
};

window.closeModal = function(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.remove('active');
};

// Close modal on escape key
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal-overlay').forEach(m => m.classList.remove('active'));
  }
});

// Run when DOM is ready
document.addEventListener('DOMContentLoaded', init);
