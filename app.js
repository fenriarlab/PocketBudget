// App State (Zero Network, 100% LocalStorage)
let appState = {
    budget: 5000, // Default budget
    transactions: [],
    goals: [],
    txFilter: 'ALL',
    selectedCategory: 'cat_food',
    formType: 'EXPENSE'
};

// Preset Categories
const categories = {
    EXPENSE: [
        { id: 'cat_food', name: '餐饮', icon: '🍔' },
        { id: 'cat_transport', name: '交通', icon: '🚌' },
        { id: 'cat_shopping', name: '购物', icon: '🛍️' },
        { id: 'cat_housing', name: '居住', icon: '🏠' },
        { id: 'cat_entertainment', name: '娱乐', icon: '🎮' },
        { id: 'cat_other_exp', name: '其他', icon: '📦' }
    ],
    INCOME: [
        { id: 'cat_salary', name: '工资收入', icon: '💰' },
        { id: 'cat_bonus', name: '理财/奖金', icon: '📈' },
        { id: 'cat_other_inc', name: '其他收入', icon: '💵' }
    ]
};

let chartInstance = null;

// Initialize App
document.addEventListener('DOMContentLoaded', () => {
    loadLocalData();
    setDefaultDates();
    renderAll();
});

function loadLocalData() {
    const saved = localStorage.getItem('pocket_budget_data');
    if (saved) {
        try {
            appState = { ...appState, ...JSON.parse(saved) };
        } catch (e) {
            console.error('Failed to parse local storage', e);
        }
    } else {
        // Seed default sample offline data if empty
        appState.transactions = [
            { id: 'tx_1', amount: 35.5, type: 'EXPENSE', categoryId: 'cat_food', categoryName: '餐饮', categoryIcon: '🍔', date: getFormattedDate(0), note: '午餐牛肉面' },
            { id: 'tx_2', amount: 8.0, type: 'EXPENSE', categoryId: 'cat_transport', categoryName: '交通', categoryIcon: '🚌', date: getFormattedDate(0), note: '地铁' },
            { id: 'tx_3', amount: 12000.0, type: 'INCOME', categoryId: 'cat_salary', categoryName: '工资收入', categoryIcon: '💰', date: getFormattedDate(-2), note: '7月工资发牌' }
        ];
        appState.goals = [
            { id: 'goal_1', title: '更换 MacBook M3 Pro', targetAmount: 15000, currentAmount: 6200, targetDate: '2026-10-01' },
            { id: 'goal_2', title: '应急备用金 (3个月)', targetAmount: 30000, currentAmount: 18500, targetDate: '2026-12-31' }
        ];
        saveLocalData();
    }
}

function saveLocalData() {
    localStorage.setItem('pocket_budget_data', JSON.stringify({
        budget: appState.budget,
        transactions: appState.transactions,
        goals: appState.goals
    }));
}

function getFormattedDate(offsetDays = 0) {
    const d = new Date();
    d.setDate(d.getDate() + offsetDays);
    return d.toISOString().split('T')[0];
}

function setDefaultDates() {
    document.getElementById('tx-date').value = getFormattedDate();
    document.getElementById('budget-input').value = appState.budget;
}

// Navigation & Tab Switching
function switchTab(tabId) {
    document.querySelectorAll('.tab-page').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
    
    document.getElementById(`tab-${tabId}`).classList.add('active');
    document.getElementById(`nav-${tabId}`).classList.add('active');

    const titles = {
        dashboard: '主页看板',
        transactions: '账单明细',
        savings: '存钱计划',
        budget: '预算评估',
        privacy: '本地数据与隐私'
    };
    document.getElementById('page-title').innerText = titles[tabId] || 'PocketBudget';

    if (tabId === 'dashboard') {
        renderDashboard();
    } else if (tabId === 'transactions') {
        renderTransactions();
    } else if (tabId === 'savings') {
        renderSavings();
    } else if (tabId === 'budget') {
        renderBudgetAssessment();
    }
}

// Render All Components
function renderAll() {
    renderDashboard();
    renderTransactions();
    renderSavings();
    renderBudgetAssessment();
}

// 1. Dashboard Render
function renderDashboard() {
    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    
    // Filter monthly transactions
    const monthlyTxs = appState.transactions.filter(t => t.date.startsWith(currentMonth));
    const totalExpense = monthlyTxs.filter(t => t.type === 'EXPENSE').reduce((s, t) => s + t.amount, 0);
    const totalIncome = monthlyTxs.filter(t => t.type === 'INCOME').reduce((s, t) => s + t.amount, 0);
    const totalSavings = appState.goals.reduce((s, g) => s + g.currentAmount, 0);

    const remainingBudget = appState.budget - totalExpense;
    const usedPct = appState.budget > 0 ? (totalExpense / appState.budget) * 100 : 0;

    // Update numbers
    document.getElementById('dash-remaining-budget').innerText = `¥ ${remainingBudget.toFixed(2)}`;
    document.getElementById('dash-total-budget').innerText = `¥ ${appState.budget.toFixed(2)}`;
    document.getElementById('dash-used-budget').innerText = `¥ ${totalExpense.toFixed(2)}`;
    document.getElementById('dash-budget-progress-fill').style.width = `${Math.min(usedPct, 100)}%`;

    document.getElementById('dash-total-expense').innerText = `¥ ${totalExpense.toFixed(2)}`;
    document.getElementById('dash-total-income').innerText = `¥ ${totalIncome.toFixed(2)}`;
    document.getElementById('dash-savings-total').innerText = `¥ ${totalSavings.toFixed(2)}`;

    // Daily Available Calculation
    const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
    const daysRemaining = daysInMonth - now.getDate() + 1;
    const dailyAvailable = remainingBudget > 0 ? remainingBudget / daysRemaining : 0;
    
    const dailyElem = document.getElementById('dash-daily-available');
    dailyElem.innerText = `¥ ${dailyAvailable.toFixed(2)} / 天`;
    
    if (dailyAvailable <= 0) {
        dailyElem.style.color = 'var(--color-alert)';
        document.getElementById('dash-daily-tip').innerText = `⚠️ 已超支！距离月底还剩 ${daysRemaining} 天，请严格控制开销。`;
    } else {
        dailyElem.style.color = 'var(--color-income)';
        document.getElementById('dash-daily-tip').innerText = `本月还剩 ${daysRemaining} 天，每天建议支出不高于此额度即可避免超支。`;
    }

    // Render Recent 5 Transactions
    const recentList = document.getElementById('dash-recent-list');
    recentList.innerHTML = '';
    const recentTxs = [...appState.transactions].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 5);
    
    if (recentTxs.length === 0) {
        recentList.innerHTML = '<p style="color: var(--text-secondary); text-align: center; padding: 20px;">暂无记账明细</p>';
    } else {
        recentTxs.forEach(tx => {
            recentList.appendChild(createTxElement(tx));
        });
    }

    // Render Pie Chart
    renderPieChart(monthlyTxs);
}

function createTxElement(tx) {
    const div = document.createElement('div');
    div.className = 'tx-item';
    const isExpense = tx.type === 'EXPENSE';
    div.innerHTML = `
        <div class="tx-left">
            <div class="tx-icon">${tx.categoryIcon || '📝'}</div>
            <div>
                <div class="tx-title">${tx.categoryName} ${tx.note ? `<span style="font-weight:400; color:var(--text-secondary); font-size:13px;">(${tx.note})</span>` : ''}</div>
                <div class="tx-date">${tx.date}</div>
            </div>
        </div>
        <div class="tx-amount ${tx.type}">
            ${isExpense ? '-' : '+'}${tx.amount.toFixed(2)}
        </div>
    `;
    return div;
}

function renderPieChart(monthlyTxs) {
    const ctx = document.getElementById('categoryPieChart').getContext('2d');
    const expenses = monthlyTxs.filter(t => t.type === 'EXPENSE');

    const catMap = {};
    expenses.forEach(t => {
        catMap[t.categoryName] = (catMap[t.categoryName] || 0) + t.amount;
    });

    const labels = Object.keys(catMap);
    const data = Object.values(catMap);

    if (chartInstance) {
        chartInstance.destroy();
    }

    chartInstance = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels.length ? labels : ['暂无数据'],
            datasets: [{
                data: data.length ? data : [1],
                backgroundColor: [
                    '#ff7675', '#74b9ff', '#a29bfe', '#ffeaa7', '#fd79a8', '#00cec9'
                ],
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'right',
                    labels: { color: '#f8f9fa', font: { family: 'Inter', size: 12 } }
                }
            }
        }
    });
}

// 2. Transactions Tab Render
function renderTransactions() {
    const container = document.getElementById('full-tx-list');
    const query = document.getElementById('tx-search-input').value.trim().toLowerCase();
    container.innerHTML = '';

    let list = [...appState.transactions];
    if (appState.txFilter !== 'ALL') {
        list = list.filter(t => t.type === appState.txFilter);
    }
    if (query) {
        list = list.filter(t => (t.note || '').toLowerCase().includes(query) || t.categoryName.toLowerCase().includes(query));
    }

    list.sort((a, b) => new Date(b.date) - new Date(a.date));

    if (list.length === 0) {
        container.innerHTML = '<p style="color: var(--text-secondary); text-align: center; padding: 40px;">没有找到符合条件的记账记录</p>';
        return;
    }

    list.forEach(tx => {
        const item = createTxElement(tx);
        // Add delete action
        const delBtn = document.createElement('button');
        delBtn.className = 'btn-icon';
        delBtn.innerHTML = '🗑️';
        delBtn.style.marginLeft = '12px';
        delBtn.onclick = (e) => {
            e.stopPropagation();
            deleteTransaction(tx.id);
        };
        item.appendChild(delBtn);
        container.appendChild(item);
    });
}

function setTxFilter(type) {
    appState.txFilter = type;
    document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
    document.getElementById(`filter-${type.toLowerCase()}`).classList.add('active');
    renderTransactions();
}

function deleteTransaction(id) {
    if (confirm('确认删除该笔账单记录？')) {
        appState.transactions = appState.transactions.filter(t => t.id !== id);
        saveLocalData();
        renderAll();
    }
}

// Modal Handlers for Transaction
function openAddTransactionModal() {
    setTxFormType('EXPENSE');
    document.getElementById('modal-transaction').classList.add('active');
}

function setTxFormType(type) {
    appState.formType = type;
    document.getElementById('btn-type-expense').classList.toggle('active', type === 'EXPENSE');
    document.getElementById('btn-type-income').classList.toggle('active', type === 'INCOME');

    const catGrid = document.getElementById('category-picker');
    catGrid.innerHTML = '';
    const catList = categories[type];
    
    appState.selectedCategory = catList[0].id;

    catList.forEach(cat => {
        const div = document.createElement('div');
        div.className = `cat-item ${cat.id === appState.selectedCategory ? 'selected' : ''}`;
        div.innerHTML = `<span style="font-size:22px">${cat.icon}</span><span>${cat.name}</span>`;
        div.onclick = () => {
            document.querySelectorAll('.cat-item').forEach(c => c.classList.remove('selected'));
            div.classList.add('selected');
            appState.selectedCategory = cat.id;
        };
        catGrid.appendChild(div);
    });
}

function handleSaveTransaction(e) {
    e.preventDefault();
    const amount = parseFloat(document.getElementById('tx-amount').value);
    const date = document.getElementById('tx-date').value;
    const note = document.getElementById('tx-note').value;
    
    if (isNaN(amount) || amount <= 0) {
        alert('请输入有效的金额');
        return;
    }

    const catList = categories[appState.formType];
    const catObj = catList.find(c => c.id === appState.selectedCategory) || catList[0];

    const newTx = {
        id: 'tx_' + Date.now(),
        amount: amount,
        type: appState.formType,
        categoryId: catObj.id,
        categoryName: catObj.name,
        categoryIcon: catObj.icon,
        date: date,
        note: note
    };

    appState.transactions.push(newTx);
    saveLocalData();
    renderAll();
    closeModal('modal-transaction');
    document.getElementById('tx-form').reset();
    setDefaultDates();
}

// 3. Savings Goals Render
function renderSavings() {
    const container = document.getElementById('goals-container');
    container.innerHTML = '';

    if (appState.goals.length === 0) {
        container.innerHTML = '<p style="color: var(--text-secondary); grid-column: 1/-1; text-align: center; padding: 40px;">暂无存钱计划，点击右上方创建一个吧！</p>';
        return;
    }

    appState.goals.forEach(goal => {
        const pct = Math.min((goal.currentAmount / goal.targetAmount) * 100, 100);
        const remaining = Math.max(goal.targetAmount - goal.currentAmount, 0);

        const card = document.createElement('div');
        card.className = 'card goal-card';
        card.innerHTML = `
            <div>
                <div class="goal-header">
                    <div>
                        <h3>🎯 ${goal.title}</h3>
                        <div class="goal-dates">目标日期: ${goal.targetDate}</div>
                    </div>
                    <button class="btn-icon" onclick="deleteGoal('${goal.id}')">🗑️</button>
                </div>
                
                <div class="goal-progress-section">
                    <div class="goal-numbers">
                        <span>已存: <strong>¥${goal.currentAmount.toFixed(2)}</strong></span>
                        <span>目标: <strong>¥${goal.targetAmount.toFixed(2)}</strong></span>
                    </div>
                    <div class="budget-progress-bar">
                        <div class="progress-fill" style="width: ${pct}%; background: var(--savings-gradient);"></div>
                    </div>
                    <div style="font-size:12px; color:var(--text-secondary); text-align:right;">达成进度: ${pct.toFixed(1)}%</div>
                </div>
            </div>

            <div style="display:flex; gap:10px;">
                <button class="btn-primary-gradient" style="flex:1" onclick="openInjectModal('${goal.id}')">+ 存入资金</button>
            </div>
        `;
        container.appendChild(card);
    });
}

function openAddGoalModal() {
    document.getElementById('modal-goal').classList.add('active');
}

function handleSaveGoal(e) {
    e.preventDefault();
    const title = document.getElementById('goal-title').value;
    const target = parseFloat(document.getElementById('goal-target').value);
    const date = document.getElementById('goal-date').value;

    if (!title || isNaN(target) || target <= 0) {
        alert('请填写完整的目标信息');
        return;
    }

    appState.goals.push({
        id: 'goal_' + Date.now(),
        title: title,
        targetAmount: target,
        currentAmount: 0,
        targetDate: date
    });

    saveLocalData();
    renderAll();
    closeModal('modal-goal');
    document.getElementById('goal-form').reset();
}

function openInjectModal(goalId) {
    document.getElementById('inject-goal-id').value = goalId;
    document.getElementById('modal-inject').classList.add('active');
}

function handleInjectSavings(e) {
    e.preventDefault();
    const goalId = document.getElementById('inject-goal-id').value;
    const amount = parseFloat(document.getElementById('inject-amount').value);

    if (isNaN(amount) || amount <= 0) {
        alert('请输入有效的金额');
        return;
    }

    const goal = appState.goals.find(g => g.id === goalId);
    if (goal) {
        goal.currentAmount += amount;
        saveLocalData();
        renderAll();
    }
    closeModal('modal-inject');
    document.getElementById('inject-form').reset();
}

function deleteGoal(id) {
    if (confirm('确认删除该存钱目标？')) {
        appState.goals = appState.goals.filter(g => g.id !== id);
        saveLocalData();
        renderAll();
    }
}

// 4. Budget Assessment & Form
function renderBudgetAssessment() {
    const now = new Date();
    const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
    const currentDay = now.getDate();
    const timePct = (currentDay / daysInMonth) * 100;

    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const monthlyTxs = appState.transactions.filter(t => t.date.startsWith(currentMonth));
    const totalExpense = monthlyTxs.filter(t => t.type === 'EXPENSE').reduce((s, t) => s + t.amount, 0);

    const budgetPct = appState.budget > 0 ? (totalExpense / appState.budget) * 100 : 0;

    const speedBox = document.getElementById('speed-indicator-box');
    const speedStatus = document.getElementById('speed-status-text');
    const speedDetail = document.getElementById('speed-detail-text');

    if (budgetPct > timePct + 15) {
        speedStatus.innerText = '⚠️ 预算消耗过快！';
        speedStatus.style.color = 'var(--color-alert)';
        speedBox.style.borderColor = 'var(--color-alert)';
    } else {
        speedStatus.innerText = '✅ 消费速度健康';
        speedStatus.style.color = 'var(--color-income)';
        speedBox.style.borderColor = 'rgba(85, 230, 193, 0.3)';
    }

    speedDetail.innerText = `本月时间已过 ${timePct.toFixed(1)}%，预算已消耗 ${budgetPct.toFixed(1)}% (已支出 ¥${totalExpense.toFixed(2)} / 总预算 ¥${appState.budget.toFixed(2)})。`;
}

function saveBudgetSetting() {
    const val = parseFloat(document.getElementById('budget-input').value);
    if (isNaN(val) || val < 0) {
        alert('请输入有效的预算金额');
        return;
    }
    appState.budget = val;
    saveLocalData();
    renderAll();
    alert('月度预算更新成功！');
}

// 5. Data Privacy Export / Import Backup
function exportDataJSON() {
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(appState, null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", `pocket_budget_backup_${getFormattedDate()}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
}

function importDataJSON(e) {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = function(evt) {
        try {
            const imported = JSON.parse(evt.target.result);
            if (imported.transactions && imported.goals) {
                appState = { ...appState, ...imported };
                saveLocalData();
                renderAll();
                alert('数据恢复成功！');
            } else {
                alert('备用文件格式不正确！');
            }
        } catch (err) {
            alert('读取备份文件失败，请重试。');
        }
    };
    reader.readAsText(file);
}

function clearAllLocalData() {
    if (confirm('确认清空所有本地数据？本操作不可撤销！')) {
        localStorage.removeItem('pocket_budget_data');
        appState.transactions = [];
        appState.goals = [];
        appState.budget = 5000;
        renderAll();
        alert('所有本地数据已彻底抹除！');
    }
}

// Modal Helpers
function closeModal(id) {
    document.getElementById(id).classList.remove('active');
}
