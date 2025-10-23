/* js/links-ui.js */
(function(){
  // ===== Safety: config & client =====
  if (!window.__SB || !window.__SB.URL || !window.__SB.ANON_KEY) {
    console.error('Missing Supabase config in js/sb-config.js');
    return;
  }
  const sb = window.supabase.createClient(window.__SB.URL, window.__SB.ANON_KEY);

  // ===== DOM refs - will be initialized after DOM is ready =====
  let tb, dbg, totalEl, refresh, f, inSlug, inUrl, inAct, btnReset;
  let editingSlug = null; // null=create, string=editing slug

  // ===== Utils =====
  function setDebug(t){ if (dbg) dbg.textContent = t || ''; }
  function validSlug(s){ return /^[a-zA-Z0-9_-]{1,64}$/.test(s); }
  function validUrl(u){ try{ const x=new URL(u); return ['http:','https:'].includes(x.protocol);}catch(e){return false;} }

  // Generate alternative slug suggestions
  function generateSlugAlternatives(baseSlug) {
    const alternatives = [];
    const timestamp = Date.now().toString().slice(-4); // Last 4 digits
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    
    alternatives.push(`${baseSlug}-${timestamp}`);
    alternatives.push(`${baseSlug}-${random}`);
    alternatives.push(`${baseSlug}-new`);
    alternatives.push(`${baseSlug}-v2`);
    
    return alternatives;
  }

  // Check if slug exists and return suggestions
  async function checkSlugExists(slug) {
    try {
      const { data: existingLinks, error } = await sb
        .from('links')
        .select('slug')
        .eq('slug', slug);

      if (error) {
        console.error('Error checking slug:', error);
        return { exists: false, suggestions: [] };
      }

      const exists = existingLinks && existingLinks.length > 0;
      const suggestions = exists ? generateSlugAlternatives(slug) : [];
      
      return { exists, suggestions };
    } catch (err) {
      console.error('Error in checkSlugExists:', err);
      return { exists: false, suggestions: [] };
    }
  }

  // Show slug suggestions with clickable options
  function showSlugSuggestions(originalSlug, suggestions) {
    if (!dbg) return;
    
    let html = `
      <div style="color: #cc0000; margin-bottom: 10px;">
        <strong>Error:</strong> The slug "${originalSlug}" already exists.
      </div>
    `;
    
    if (suggestions.length > 0) {
      html += `
        <div style="margin-bottom: 10px;">
          <strong>Suggested alternatives:</strong>
        </div>
        <div style="display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 10px;">
      `;
      
      suggestions.forEach((suggestion, index) => {
        html += `
          <button 
            type="button" 
            class="suggestion-btn" 
            data-suggestion="${suggestion}"
            style="
              background: #007bff; 
              color: white; 
              border: none; 
              padding: 4px 8px; 
              border-radius: 4px; 
              font-size: 0.8rem; 
              cursor: pointer;
              transition: background 0.2s;
            "
            onmouseover="this.style.background='#0056b3'"
            onmouseout="this.style.background='#007bff'"
          >
            ${suggestion}
          </button>
        `;
      });
      
      html += `
        </div>
        <div style="font-size: 0.8rem; color: #666;">
          Click on a suggestion to use it.
        </div>
      `;
    }
    
    dbg.innerHTML = html;
    
    // Add click handlers for suggestion buttons
    dbg.querySelectorAll('.suggestion-btn').forEach(btn => {
      btn.addEventListener('click', function() {
        const suggestedSlug = this.getAttribute('data-suggestion');
        if (inSlug) {
          inSlug.value = suggestedSlug;
          setDebug('');
          console.log('Using suggested slug:', suggestedSlug);
        }
      });
    });
  }

  // ===== List =====
  async function loadLinks(){
    setDebug('');
    if (!tb) {
      console.error('Table body not found');
      return;
    }

    console.log('Loading links...');
    tb.innerHTML = '<tr><td colspan="7" style="text-align:center;color:#6c757d;padding:40px;font-style:italic;">Loading links...</td></tr>';
    
    try {
      // First, check if we have any links at all
      console.log('Checking links table directly...');
      const { data: directLinks, error: directError } = await sb
        .from('links')
        .select('slug, target_url, active, updated_at')
        .order('updated_at', { ascending: false });

      if (directError) {
        console.error('Direct links query error:', directError);
        tb.innerHTML = '<tr><td colspan="7" style="text-align:center;color:#dc3545;padding:40px;font-weight:500;">Database error: ' + directError.message + '</td></tr>';
        setDebug('Database error: ' + directError.message);
        return;
      }

      console.log('Direct links query result:', directLinks);

      if (!directLinks || directLinks.length === 0) {
        console.log('No links found in database');
        tb.innerHTML = '<tr><td colspan="7" style="text-align:center;color:#666">No links found. Create your first link below!</td></tr>';
        if (totalEl) totalEl.textContent = '0';
        setDebug('No links in database. Create your first link!');
        return;
      }

      // Try to load from links_with_counts view for click counts
      console.log('Trying to load from links_with_counts view...');
      const { data: viewData, error: viewError } = await sb
        .from('links_with_counts')
        .select('slug, target_url, active, updated_at, total_clicks, last_click_at')
        .order('updated_at', { ascending: false });

      if (!viewError && viewData && viewData.length > 0) {
        console.log('View data loaded successfully:', viewData);
        renderLinksTable(viewData);
        return;
      }

      // If view fails, use direct links data with zero counts
      console.log('View failed or empty, using direct links data. View error:', viewError);
      const transformedData = directLinks.map(link => ({
        ...link,
        total_clicks: 0,
        last_click_at: null
      }));
      
      console.log('Using transformed data:', transformedData);
      renderLinksTable(transformedData);
      
    } catch (err) {
      console.error('Unexpected error loading links:', err);
      tb.innerHTML = '<tr><td colspan="7" style="text-align:center;color:#dc3545;padding:40px;font-weight:500;">Unexpected error: ' + err.message + '</td></tr>';
      setDebug('Unexpected error: ' + err.message);
    }
  }

  function renderLinksTable(data) {
    if (!tb) return;
    
    if (!data || data.length === 0) {
      tb.innerHTML = '<tr><td colspan="7" style="text-align:center;color:#666;padding:40px;font-style:italic;">No links found. Create your first link below!</td></tr>';
      if (totalEl) totalEl.textContent = '0';
      return;
    }

    // Limit display to 5 links maximum
    const displayData = data.slice(0, 5);
    const hasMore = data.length > 5;

    tb.innerHTML = displayData.map(l => `
      <tr>
        <td class="slug-cell">${l.slug}</td>
        <td class="url-cell" title="${l.target_url}">${l.target_url}</td>
        <td class="${l.active ? 'status-active' : 'status-inactive'}">${l.active ? '✓ Active' : '✗ Inactive'}</td>
        <td><span class="clicks-count">${l.total_clicks || 0}</span></td>
        <td class="last-click">${l.last_click_at ? new Date(l.last_click_at).toLocaleString() : 'Never'}</td>
        <td class="updated-at">${new Date(l.updated_at).toLocaleString()}</td>
        <td>
          <div class="action-buttons">
            <button class="btn btn-sm" onclick="startEditLink('${l.slug}')">Edit</button>
            <button class="btn btn-sm" onclick="deleteLink('${l.slug}')" style="background:#666666;color:white;">Delete</button>
          </div>
        </td>
      </tr>
    `).join('');

    // Add "more links" indicator if there are more than 5
    if (hasMore) {
      const moreCount = data.length - 5;
      tb.innerHTML += `
        <tr>
          <td colspan="7" style="text-align:center;color:#6c757d;padding:12px;font-style:italic;background:#f8f9fa;">
            ... and ${moreCount} more link${moreCount > 1 ? 's' : ''} (scroll to see all)
          </td>
        </tr>
      `;
    }

    if (totalEl) totalEl.textContent = data.length.toString();
    console.log('Table rendered with', displayData.length, 'visible links out of', data.length, 'total');
  }

  // ===== Form =====
  function resetForm(){
    editingSlug = null;
    if (inSlug) inSlug.value = '';
    if (inUrl) inUrl.value = '';
    if (inAct) inAct.checked = true;
    setDebug('');
    console.log('Form reset');
  }

  function startEditLink(slug){
    console.log('Starting edit for slug:', slug);
    // Load the link data
    sb.from('links').select('*').eq('slug', slug).single().then(({data, error}) => {
      if (error) {
        console.error('Error loading link for edit:', error);
        setDebug('Error loading link: ' + error.message);
        return;
      }
      if (data) {
        editingSlug = slug;
        if (inSlug) inSlug.value = data.slug;
        if (inUrl) inUrl.value = data.target_url;
        if (inAct) inAct.checked = data.active;
        setDebug('Editing: ' + slug);
        console.log('Form populated for edit:', data);
      }
    });
  }

  async function deleteLink(slug){
    if (!confirm('Delete link "' + slug + '"?')) return;
    console.log('Deleting link:', slug);
    
    try {
      const { error } = await sb.from('links').delete().eq('slug', slug);
      if (error) {
        console.error('Delete error:', error);
        setDebug('Error deleting link: ' + error.message);
        return;
      }
      console.log('Link deleted successfully');
      setDebug('');
      await loadLinks();
    } catch (err) {
      console.error('Unexpected delete error:', err);
      setDebug('Unexpected error: ' + err.message);
    }
  }

  // ===== DOM init =====
  function initDOMElements() {
    tb = document.getElementById('links-tbody');
    dbg = document.getElementById('linksDebug');
    totalEl = document.getElementById('linksTotal');
    refresh = document.getElementById('linksRefresh');
    f = document.getElementById('linkForm');
    inSlug = document.getElementById('slugInput');
    inUrl = document.getElementById('urlInput');
    inAct = document.getElementById('activeInput');
    btnReset = document.getElementById('resetBtn');

    console.log('DOM elements initialized:', {
      tb: !!tb,
      dbg: !!dbg,
      totalEl: !!totalEl,
      refresh: !!refresh,
      f: !!f,
      inSlug: !!inSlug,
      inUrl: !!inUrl,
      inAct: !!inAct,
      btnReset: !!btnReset
    });

    return tb && dbg && totalEl && refresh && f && inSlug && inUrl && inAct && btnReset;
  }

  // ===== init =====
  async function initializeLinksUI() {
    console.log('Initializing Links UI...');
    
    // Initialize DOM elements
    if (!initDOMElements()) {
      console.error('Failed to initialize DOM elements');
      return;
    }
    
    // Set up event listeners
    if (btnReset) btnReset.onclick = resetForm;
    if (refresh) refresh.onclick = loadLinks;
    
    if (f) {
      f.addEventListener('submit', async (e)=>{
        e.preventDefault();
        const slug = (inSlug?.value || '').trim();
        const url  = (inUrl?.value  || '').trim();
        const act  = !!inAct?.checked;
        setDebug('');

        console.log('Submitting link:', { slug, url, act, editingSlug });

        if (!validSlug(slug)){ setDebug('Slug chỉ gồm a-z, A-Z, 0-9, _ và - (<=64 ký tự).'); return; }
        if (!validUrl(url)){ setDebug('Target URL phải bắt đầu bằng http:// hoặc https://'); return; }

        try {
          if (!editingSlug){
            console.log('Creating new link...');
            
            // Check if slug exists and get suggestions
            const { exists, suggestions } = await checkSlugExists(slug);

            if (exists) {
              console.error('Create error: Slug already exists');
              showSlugSuggestions(slug, suggestions);
              return;
            }

            // If the slug doesn't exist, proceed with the insert
            const { error: insertError } = await sb
              .from('links')
              .insert({ slug, target_url: url, active: act });
              
            if (insertError){ 
              console.error('Create error:', insertError);
              setDebug('Error creating link: ' + insertError.message); 
              return; 
            }
            console.log('Link created successfully');
          } else {
            console.log('Updating existing link...');
            
            // For updates, check if new slug conflicts with other records (excluding current one)
            if (slug !== editingSlug) {
              const { data: existingLinks, error: fetchError } = await sb
                .from('links')
                .select('slug')
                .eq('slug', slug)
                .neq('slug', editingSlug);

              if (fetchError) {
                console.error('Error checking for existing link:', fetchError);
                setDebug('Error checking for existing link: ' + fetchError.message);
                return;
              }

              if (existingLinks && existingLinks.length > 0) {
                console.error('Update error: Slug already exists');
                setDebug('Error updating link: The slug "' + slug + '" already exists. Please choose a different slug.');
                return;
              }
            }
            
            const { error: updateError } = await sb
              .from('links')
              .update({ slug, target_url: url, active: act })
              .eq('slug', editingSlug);
              
            if (updateError){ 
              console.error('Update error:', updateError);
              setDebug('Error updating link: ' + updateError.message); 
              return; 
            }
            console.log('Link updated successfully');
          }
          resetForm();
          await loadLinks();
        } catch (err) {
          console.error('Unexpected error:', err);
          setDebug('Unexpected error: ' + err.message);
        }
      });
    }
    
    // Load initial data
    loadLinks();
  }
  
  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeLinksUI);
  } else {
    // DOM already ready, initialize immediately
    setTimeout(initializeLinksUI, 50);
  }
  
  // Expose function for manual loading
  window.loadLinksFromDashboard = async function() {
    console.log('Manual load triggered');
    
    if (tb) {
      loadLinks();
    } else {
      console.log('DOM not ready, initializing...');
      await initializeLinksUI();
    }
  };

  // Expose functions globally for onclick handlers
  window.startEditLink = startEditLink;
  window.deleteLink = deleteLink;

})();