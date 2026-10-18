// 一、查詢課程與教練的對應關係
// 資料來源：data.js 的 courses、coaches、coachCourses

// 輸入課程 ID，回傳這門課的授課教練姓名
function getCoachNames(courseid) {
    return coachCourses
        .filter(item => item.courseid === courseid)
        .map(item =>
            coaches.find(coach => coach.coachid === item.coachid)?.name
        )
        .filter(Boolean)
        .join("、");
}

// 輸入教練 ID，回傳這位教練教授的課程名稱
function getCourseNames(coachid) {
    return coachCourses
        .filter(item => item.coachid === coachid)
        .map(item =>
            courses.find(course => course.courseid === item.courseid)?.coursename
        )
        .filter(Boolean)
        .join("、");
}


// 二、表格共用工具

// 在指定的 <tr> 裡新增一格 <td>
// 如果資料是 null 或 undefined，顯示「未填寫」
function addCell(row, value) {
    const cell = row.insertCell();
    cell.textContent = value ?? "未填寫";
    return cell;
}


// 三、顯示課程列表
// 對應頁面：course.html
// 對應位置：<tbody id="courseTableBody">

function renderCourses() {
    const tbody = document.querySelector("#courseTableBody");

    // 在 coach.html 找不到這個 tbody，因此直接結束
    if (!tbody) return;

    // 每次重新顯示前先清空，避免資料列重複
    tbody.replaceChildren();

    courses.forEach(course => {
        // 每門課建立一列 <tr>
        const row = tbody.insertRow();

        // 修改表格欄位時，這裡的順序要和 HTML 的 <th> 一致
        addCell(row, course.courseid);
        addCell(row, course.coursename);
        addCell(row, course.coursetype);
        addCell(row, course.description);
        addCell(row, `${course.durationmin} 分鐘`);
        addCell(row, `NT$ ${course.price}`);
        addCell(row, getCoachNames(course.courseid) || "尚未指派");

        // 狀態欄：停用是紅色，上架是綠色
        const statusCell = row.insertCell();
        const badge = document.createElement("span");
        badge.className = course.status === "停用"
            ? "badge text-bg-danger"
            : "badge text-bg-success";
        badge.textContent = course.status;
        statusCell.append(badge);

        // 操作欄：每門課都有自己的編輯按鈕
        const actionCell = row.insertCell();
        const editButton = document.createElement("button");
        editButton.type = "button";
        editButton.className = "btn btn-sm btn-outline-secondary text-nowrap";
        editButton.textContent = "編輯";

        // 點擊時，把「這一筆 course」交給編輯表單
        editButton.addEventListener("click", () => openCourseForm(course));
        actionCell.append(editButton);
    });
}


// 四、顯示教練列表
// 對應頁面：coach.html
// 對應位置：<tbody id="coachTableBody">

function renderCoaches() {
    const tbody = document.querySelector("#coachTableBody");

    // 在 course.html 找不到這個 tbody，因此直接結束
    if (!tbody) return;

    tbody.replaceChildren();

    coaches.forEach(coach => {
        const row = tbody.insertRow();

        // 修改教練表格欄位時，也要同步修改 coach.html 的 <th>
        addCell(row, coach.coachid);
        addCell(row, coach.coachno);
        addCell(row, coach.name);
        addCell(row, coach.gender);
        addCell(row, coach.phone);
        addCell(row, coach.email);
        addCell(row, coach.specialty || "尚未設定");
        addCell(row, coach.status === "active" ? "在職" : "離職");

        // 最後一欄：這位教練的編輯按鈕
        const actionCell = row.insertCell();
        const editButton = document.createElement("button");
        editButton.type = "button";
        editButton.className = "btn btn-sm btn-outline-secondary text-nowrap";
        editButton.textContent = "編輯";
        editButton.addEventListener("click", () => openCoachForm(coach));
        actionCell.append(editButton);
    });
}


// 五、課程表單：新增和編輯共用同一個 Bootstrap Modal

// null：目前是新增課程
// 數字：目前正在編輯這個 courseid 的課程
let editingCourseId = null;

// 顯示所有教練的核取方塊，讓管理員選擇授課教練
function renderCoachOptions(selectedCourseId = null) {
    const container = document.querySelector("#courseCoachOptions");
    container.replaceChildren();

    coaches.forEach(coach => {
        const wrapper = document.createElement("div");
        wrapper.className = "form-check";

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.className = "form-check-input";
        checkbox.name = "coachIds";
        checkbox.value = coach.coachid;
        checkbox.id = `coachOption${coach.coachid}`;

        // 編輯課程時，勾選原本的授課教練
        checkbox.checked = coachCourses.some(item =>
            item.courseid === selectedCourseId &&
            item.coachid === coach.coachid
        );

        const label = document.createElement("label");
        label.className = "form-check-label";
        label.htmlFor = checkbox.id;
        label.textContent = coach.name;

        wrapper.append(checkbox, label);
        container.append(wrapper);
    });
}

// 開啟課程表單
// 沒有傳入 course → 新增；有傳入 course → 編輯
function openCourseForm(course = null) {
    const form = document.querySelector("#courseForm");
    form.reset();

    editingCourseId = course?.courseid ?? null;

    document.querySelector("#courseModalTitle").textContent =
        course ? "編輯課程" : "新增課程";

    // 新增課程預設上架；編輯時才顯示「停用課程」選項
    document.querySelector("#courseStatusGroup").hidden = !course;
    document.querySelector("#courseStatus").value = course?.status ?? "上架";

    // 編輯時帶入原本資料；新增時欄位留空
    document.querySelector("#courseName").value = course?.coursename ?? "";
    document.querySelector("#courseType").value =
        course?.coursetype ?? "重量訓練";
    document.querySelector("#courseDescription").value =
        course?.description ?? "";
    document.querySelector("#coursePrice").value = course?.price ?? "";

    renderCoachOptions(editingCourseId);

    // 顯示 Bootstrap Modal
    bootstrap.Modal.getOrCreateInstance(
        document.querySelector("#courseModal")
    ).show();
}



// 六、處理「新增課程」按鈕和表單儲存
// 只有 course.html 有 addCourseBtn，所以教練頁會跳過這段


const addCourseBtn = document.querySelector("#addCourseBtn");

if (addCourseBtn) {
    // 上方「新增課程」按鈕
    addCourseBtn.addEventListener("click", () => openCourseForm());

    // 按下表單的「儲存」按鈕
    document.querySelector("#courseForm").addEventListener("submit", event => {
        event.preventDefault(); // 阻止表單造成整頁重新整理

        // 取得表單輸入值
        const name = document.querySelector("#courseName").value.trim();
        const type = document.querySelector("#courseType").value;
        const description =
            document.querySelector("#courseDescription").value.trim();
        const price = Number(document.querySelector("#coursePrice").value);

        // 新增預設上架；編輯時採用管理員選的狀態
        const status = editingCourseId === null
            ? "上架"
            : document.querySelector("#courseStatus").value;

        // 取得所有被勾選的教練 ID
        const selectedCoachIds = [
            ...document.querySelectorAll('input[name="coachIds"]:checked')
        ].map(checkbox => Number(checkbox.value));

        if (editingCourseId === null) {
            // ---------- 新增課程 ----------
            // 前端測試用：取目前最大 ID + 1
            // 將來接資料庫時，正式 ID 應由 SQL Server 產生
            const newId = Math.max(0, ...courses.map(c => c.courseid)) + 1;

            courses.push({
                courseid: newId,
                coursename: name,
                coursetype: type,
                description,
                durationmin: 60,
                price,
                status
            });

            editingCourseId = newId;
        } else {
            // ---------- 編輯課程 ----------
            // 找到原本的課程，直接修改其欄位
            const course = courses.find(
                c => c.courseid === editingCourseId
            );
            if (!course) return;

            course.coursename = name;
            course.coursetype = type;
            course.description = description;
            course.price = price;
            course.status = status;
        }

        // ---------- 更新教練與課程的關聯 ----------
        // 先移除這門課原本的授課教練
        coachCourses = coachCourses.filter(
            item => item.courseid !== editingCourseId
        );

        // 再加入目前表單中勾選的教練
        selectedCoachIds.forEach(coachid => {
            coachCourses.push({
                coachid,
                courseid: editingCourseId
            });
        });

        // 陣列改變後，重新顯示表格
        renderCourses();
        renderCoaches();

        // 關閉 Modal
        bootstrap.Modal.getInstance(
            document.querySelector("#courseModal")
        ).hide();
    });
}

// null 表示新增；數字表示正在編輯的 coachid
let editingCoachId = null;

function renderCourseOptions(selectedCoachId = null) {
    const container = document.querySelector("#coachCourseOptions");
    container.replaceChildren();

    // 取得正在編輯的教練，以及原本的專長
    const selectedCoach = coaches.find(
        item => item.coachid === selectedCoachId
    );

    const selectedSpecialtyNames = (selectedCoach?.specialty ?? "")
        .split(/[、，,]/)
        .map(name => name.trim())
        .filter(Boolean);

    courses.forEach(course => {
        const wrapper = document.createElement("div");
        wrapper.className = "form-check";

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.className = "form-check-input";
        checkbox.name = "courseIds";
        checkbox.value = course.courseid;
        checkbox.id = `courseOption${course.courseid}`;

        // 依資料庫回傳的專長還原勾選
        checkbox.checked = selectedSpecialtyNames.includes(
            course.coursename
        );

        const label = document.createElement("label");
        label.className = "form-check-label";
        label.htmlFor = checkbox.id;
        label.textContent = course.coursename;

        wrapper.append(checkbox, label);
        container.append(wrapper);
    });

    if (courses.length === 0) {
        container.textContent = "目前沒有課程，請先新增課程。";
    }
}

// 開啟新增或編輯教練的 Modal
function openCoachForm(coach = null) {
    const form = document.querySelector("#coachForm");
    form.reset();

    editingCoachId = coach?.coachid ?? null;

    document.querySelector("#coachModalTitle").textContent =
        coach ? "編輯教練" : "新增教練";

    document.querySelector("#coachNo").value = coach?.coachno ?? "";
    document.querySelector("#coachName").value = coach?.name ?? "";
    document.querySelector("#coachAccountId").value = coach?.accountid ?? "";
    document.querySelector("#coachGender").value = coach?.gender ?? "";
    document.querySelector("#coachPhone").value = coach?.phone ?? "";
    document.querySelector("#coachEmail").value = coach?.email ?? "";
    renderCourseOptions(editingCoachId);

    // 新增預設「在職」；編輯時才顯示狀態選單
    document.querySelector("#coachStatusGroup").hidden = !coach;
    document.querySelector("#coachStatus").value = coach?.status ?? "active";

    bootstrap.Modal.getOrCreateInstance(
        document.querySelector("#coachModal")
    ).show();
}

const addCoachBtn = document.querySelector("#addCoachBtn");

if (addCoachBtn) {
    addCoachBtn.addEventListener("click", () => openCoachForm());

    document.querySelector("#coachForm").addEventListener(
        "submit",
        async event => {
            event.preventDefault();

            // 這一步先完成新增，編輯稍後串接
            if (editingCoachId !== null) {
                alert("編輯功能尚未串接，請先測試新增教練。");
                return;
            }

            const form = event.currentTarget;
            const saveButton = form.querySelector('button[type="submit"]');

            // 取得勾選的課程，組合成專長文字
            const selectedCourseIds = [
                ...document.querySelectorAll(
                    '#coachCourseOptions input[name="courseIds"]:checked'
                )
            ].map(checkbox => Number(checkbox.value));

            const specialty = courses
                .filter(course => selectedCourseIds.includes(course.courseid))
                .map(course => course.coursename)
                .join("、");

            // 欄位名稱對應 CoachCreateRequest
            const formData = {
                accountid: Number(
                    document.querySelector("#coachAccountId").value.trim()
                ),
                coachno: document.querySelector("#coachNo").value.trim(),
                name: document.querySelector("#coachName").value.trim(),
                gender: document.querySelector("#coachGender").value.trim(),
                phone: document.querySelector("#coachPhone").value.trim(),
                email: document.querySelector("#coachEmail").value.trim(),
                specialty: specialty || null
            };

            saveButton.disabled = true;

            try {
                // 將表單資料送到新增教練 API
                const response = await fetch("/api/coaches", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(formData)
                });

                if (!response.ok) {
                    const errorText = await response.text();
                    console.error("新增教練失敗：", response.status, errorText);

                    const messages = {
                        400: "欄位格式不正確，請檢查輸入內容。",
                        401: "請先登入管理員帳號。",
                        403: "請求被拒絕，請確認登入權限與後端設定。",
                        404: "找不到此帳號，請確認帳號 ID。",
                        409: "教練編號已存在，請更換編號。"
                    };

                    throw new Error(
                        messages[response.status]
                        || `新增失敗，狀態碼：${response.status}`
                    );
                }

                // 儲存成功後關閉視窗
                bootstrap.Modal.getInstance(
                    document.querySelector("#coachModal")
                ).hide();

                alert("新增教練成功，資料已儲存！");

                // 重新向後端查詢列表
                await loadCoaches();
            } catch (error) {
                console.error(error);
                alert(error.message);
            } finally {
                saveButton.disabled = false;
            }
        }
    );
}


// 從後端取得教練資料
async function loadCoaches() {
    try {
        const response = await fetch("/api/coaches");

        if (!response.ok) {
            throw new Error(`讀取失敗，狀態碼：${response.status}`);
        }

        const data = await response.json();

        if (!Array.isArray(data)) {
            throw new Error("後端回傳的資料不是教練陣列");
        }

        coaches = data;
        renderCoaches();
    } catch (error) {
        console.error("讀取教練失敗：", error);
        alert("無法讀取教練資料，請查看 Console 錯誤訊息。");
    }
}

renderCourses();

// 只有教練頁需要讀取教練列表
if (document.querySelector("#coachTableBody")) {
    loadCoaches();
}