// static/js/main.js

// --- 1. FIREBASE CLIENT CONFIGURATION ---

const firebaseConfig = {
    apiKey: "AIzaSyAMIFLIZ7HXZZ6QFm8Wr0g3K2NUj_YdTBA",
    authDomain: "expensetrackerflask.firebaseapp.com",
    projectId: "expensetrackerflask",
    storageBucket: "expensetrackerflask.firebasestorage.app",
    messagingSenderId: "130916575737",
    appId: "1:130916575737:web:9b56abfbb6a9635e9ff528",
    measurementId: "G-30D6J4KM1D"
};

// Initialize Firebase
if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
    console.log("Firebase Client SDK initialized.");
}
const auth = firebase.auth();


// --- 2. AUTHENTICATION LOGIC (Client-Side) ---

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    const idTokenField = document.getElementById('idToken');

    console.log("DOM Content Loaded. Login form found:", !!loginForm);

    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            const email = loginForm.elements['login-email'].value;
            const password = loginForm.elements['login-password'].value;

            try {
                const userCredential = await auth.signInWithEmailAndPassword(email, password);
                const user = userCredential.user;
                const idToken = await user.getIdToken();

                idTokenField.value = idToken;
                loginForm.submit();

            } catch (error) {
                const errorContainer = document.querySelector('.error');
                if (errorContainer) {
                    errorContainer.textContent = `Login Failed: ${error.message} (Code: ${error.code})`;
                }
                console.error("Login authentication error:", error);
            }
        });
    }

    // --- 3. DASHBOARD: CHART INITIALIZATION ---
    if (document.getElementById('mainChart')) {
        initializeCharts();
    }
});


// --- 4. CHART LOGIC ---

let mainChartInstance = null;
let currentChartType = 'expense'; // 'expense' or 'income'

const CHART_COLORS = [
    '#ff006e', // Pink/Magenta
    '#00bcd4', // Cyan
    '#ff9800', // Orange
    '#4caf50', // Green
    '#9c27b0', // Purple
    '#ffeb3b', // Yellow
    '#795548', // Brown
    '#607d8b'  // Blue Grey
];

function switchChartType(type) {
    currentChartType = type;

    // Update Toggle UI
    const expBtn = document.getElementById('toggle-expense');
    const incBtn = document.getElementById('toggle-income');

    if (expBtn && incBtn) {
        expBtn.classList.toggle('active', type === 'expense');
        incBtn.classList.toggle('active', type === 'income');
    }

    initializeCharts();
}

function initializeCharts() {
    const ctx = document.getElementById('mainChart').getContext('2d');

    // Get Data from Injected Scripts
    const expenseDataEl = document.getElementById('expenseData');
    const incomeDataEl = document.getElementById('incomeData');

    if (!expenseDataEl || !incomeDataEl) return;

    const expenseDataRaw = JSON.parse(expenseDataEl.textContent || '{}');
    const incomeDataRaw = JSON.parse(incomeDataEl.textContent || '{}');

    const dataMap = currentChartType === 'expense' ? expenseDataRaw : incomeDataRaw;
    const labels = Object.keys(dataMap);
    const values = Object.values(dataMap).map(v => v / 100); // Convert cents to units

    const total = values.reduce((a, b) => a + b, 0);
    const totalEl = document.getElementById('chartTotalAmount');
    if (totalEl) {
        totalEl.textContent = total.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 });
    }

    // Render Breakdown List
    renderBreakdownList(labels, values, total);

    // Prepare Chart Data
    const chartData = {
        labels: labels,
        datasets: [{
            data: values,
            backgroundColor: CHART_COLORS,
            borderWidth: 0,
            hoverOffset: 4
        }]
    };

    // Destroy existing chart
    if (mainChartInstance) {
        mainChartInstance.destroy();
    }

    // Create New Chart
    mainChartInstance = new Chart(ctx, {
        type: 'doughnut',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '70%', // Thinner donut
            plugins: {
                legend: { display: false }, // Custom breakdown list used instead
                tooltip: {
                    callbacks: {
                        label: function (context) {
                            let label = context.label || '';
                            if (label) {
                                label += ': ';
                            }
                            if (context.parsed !== null) {
                                label += context.parsed.toLocaleString();
                            }
                            return label;
                        }
                    }
                }
            }
        }
    });
}

function renderBreakdownList(labels, values, total) {
    const listContainer = document.getElementById('breakdownList');
    if (!listContainer) return;

    listContainer.innerHTML = '';

    if (labels.length === 0) {
        listContainer.innerHTML = '<div style="text-align:center; color:#9ca3af; font-size:0.9em;">No data to display</div>';
        return;
    }

    // Combine labels and values for sorting
    const items = labels.map((label, i) => ({
        label: label,
        value: values[i],
        color: CHART_COLORS[i % CHART_COLORS.length]
    }));

    // Sort by value descending
    items.sort((a, b) => b.value - a.value);

    items.forEach(item => {
        const percent = total > 0 ? ((item.value / total) * 100).toFixed(1) + '%' : '0%';

        const itemDiv = document.createElement('div');
        itemDiv.className = 'breakdown-item';

        itemDiv.innerHTML = `
            <div class="bd-left">
                <div class="bd-color-dot" style="background-color: ${item.color};"></div>
                <span class="bd-name">${item.label}</span>
                <span class="bd-percent">${percent}</span>
            </div>
            <div class="bd-amount">${item.value.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</div>
        `;

        listContainer.appendChild(itemDiv);
    });
}